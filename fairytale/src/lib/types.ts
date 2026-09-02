export interface StoryPage {
  pageNumber: number;
  script: string;
  imageUrl: string | null;
}

export interface Story {
  id: string;
  title: string;
  theme: string;
  audioUrl: string;
  pages: StoryPage[];
  prompt?: string | null;
  additionalContext?: string | null;
  isDefault?: boolean;
  visitorId?: string | null;
  source?: string;
  createdAt: string;
}

export interface FeedbackOptions {
  Positive: string[];
  Negative: string[];
}

export interface AdminStatsSeriesPoint {
  period: string;
  visitors: number;
}

export interface AdminStats {
  totalUsers: number;
  totalStories: number;
  totalFeedback: number;
  rangeVisitors: number;
  rangeVisits: number;
  start: string;
  end: string;
  granularity: string;
  series: AdminStatsSeriesPoint[];
}

export const THEME_OPTIONS = [
  { name: "Adventure", description: "Brave heroes, quests and thrilling discoveries", color: "#8E44AD" },
  { name: "Fantasy", description: "Mystical creatures and enchanted worlds", color: "#9B59B6" },
  { name: "Space", description: "Futuristic technology and cosmic exploration", color: "#34495E" },
  { name: "Nature", description: "Animals, plants and the beauty of the outdoors", color: "#27AE60" },
  { name: "Friendship", description: "Kindness, teamwork and helping others", color: "#F39C12" },
  { name: "Science", description: "Fun scientific concepts, explained through story", color: "#3498DB" },
] as const;

export function themeColor(theme: string): string {
  return THEME_OPTIONS.find((t) => t.name.toLowerCase() === theme.toLowerCase())?.color ?? "#4A90E2";
}
