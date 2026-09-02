from datetime import datetime, timezone
from typing import Dict, Any, List, Optional
import uuid


class FeedbackService:
    def __init__(self, db=None):
        # Mongo-backed when a db handle is supplied; falls back to an
        # in-memory list only when Mongo isn't configured (e.g. local dev
        # without MONGODB_URI set).
        self._col = db.feedback if db is not None else None
        self._feedback: List[Dict[str, Any]] = []
        self.feedback_options = {
            "Positive": [
                "Great content",
                "Easy to understand",
                "Visually appealing",
                "Informative",
                "Well structured",
                "Other",
            ],
            "Negative": [
                "Confusing Too complex",
                "Not visually appealing",
                "Inappropriate or harmful content",
                "Sexual or adult content",
                "Bug or technical issue",
                "Other",
            ],
        }

    def submit_feedback(
        self,
        feedback_type: str,
        selected_feedback: str,
        custom_feedback: str = "",
        story_id: Optional[str] = None,
        rating: int = 5,
        visitor_id: Optional[str] = None,
    ) -> Dict[str, Any]:
        """Submit feedback to Mongo (or the in-memory fallback)."""
        try:
            final_feedback = (
                custom_feedback if selected_feedback == "Other" else selected_feedback
            )

            if not final_feedback:
                return {
                    "success": False,
                    "error": "Please provide feedback.",
                }

            now = datetime.now(timezone.utc)
            feedback_data = {
                "id": str(uuid.uuid4()),
                "feedbackType": feedback_type,
                "selectedFeedback": selected_feedback,
                "finalFeedback": final_feedback,
                "rating": rating,
                "storyId": story_id,
                "visitorId": visitor_id,
                "submittedAt": now if self._col is not None else now.isoformat(),
            }

            if self._col is not None:
                self._col.insert_one(dict(feedback_data))
            else:
                self._feedback.append(feedback_data)
            print(f"Feedback stored: {feedback_data}")

            return {
                "success": True,
                "message": "Your feedback has been submitted successfully.",
            }

        except Exception as e:
            print(f"Error submitting feedback: {e}")
            return {
                "success": False,
                "error": f"Failed to submit feedback: {e}",
            }

    def get_feedback_options(self) -> Dict[str, List[str]]:
        """Get available feedback options"""
        return self.feedback_options

    def get_feedback_for_story(self, story_id: str) -> List[Dict[str, Any]]:
        """Get all feedback for a specific story"""
        try:
            if self._col is not None:
                docs = list(self._col.find({"storyId": story_id}).sort("submittedAt", -1))
                for doc in docs:
                    doc.pop("_id", None)
                    submitted_at = doc.get("submittedAt")
                    if isinstance(submitted_at, datetime):
                        doc["submittedAt"] = submitted_at.isoformat()
                return docs
            return [f for f in self._feedback if f.get("storyId") == story_id]
        except Exception as e:
            print(f"Error getting feedback for story: {e}")
            return []

    def get_feedback_stats(self, story_id: str) -> Dict[str, Any]:
        """Get feedback statistics for a story"""
        try:
            feedback_list = self.get_feedback_for_story(story_id)

            if not feedback_list:
                return {
                    "totalFeedback": 0,
                    "averageRating": 0.0,
                    "positiveCount": 0,
                    "negativeCount": 0,
                    "feedbackBreakdown": {},
                }

            total_feedback = len(feedback_list)
            total_rating = sum(f.get("rating", 0) for f in feedback_list)
            average_rating = total_rating / total_feedback if total_feedback > 0 else 0

            positive_count = sum(
                1 for f in feedback_list if f.get("feedbackType") == "Positive"
            )
            negative_count = total_feedback - positive_count

            feedback_breakdown = {}
            for feedback in feedback_list:
                feedback_type = feedback.get("feedbackType", "Unknown")
                feedback_breakdown[feedback_type] = (
                    feedback_breakdown.get(feedback_type, 0) + 1
                )

            return {
                "totalFeedback": total_feedback,
                "averageRating": average_rating,
                "positiveCount": positive_count,
                "negativeCount": negative_count,
                "feedbackBreakdown": feedback_breakdown,
            }

        except Exception as e:
            print(f"Error getting feedback stats: {e}")
            return {
                "totalFeedback": 0,
                "averageRating": 0.0,
                "positiveCount": 0,
                "negativeCount": 0,
                "feedbackBreakdown": {},
            }
