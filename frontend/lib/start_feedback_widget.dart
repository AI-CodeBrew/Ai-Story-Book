import 'package:flutter/material.dart';
import 'utils/app_sizes.dart';
import 'services/api_service.dart';


class StarFeedbackWidget extends StatefulWidget {
  final double size;
  final BuildContext mainContext;
  final bool isShowText;
  final IconData icon;

  const StarFeedbackWidget({
    Key? key,
    required this.size,
    required this.mainContext,
    this.isShowText = false,
    required this.icon,
  }) : super(key: key);

  @override
  State<StarFeedbackWidget> createState() => _StarFeedbackWidgetState();
}

class _StarFeedbackWidgetState extends State<StarFeedbackWidget> {
  bool isStarred = false; // Track if feedback is given
  String? selectedFeedback; // Selected feedback option
  String? feedbackType = "Negative"; // Default feedback type
  TextEditingController customFeedbackController = TextEditingController();

  final Map<String, List<String>> feedbackOptions = {
    "Positive": [
      "Great content",
      "Easy to understand",
      "Visually appealing",
      "Informative",
      "Well structured",
      "Other",
    ],
    "Negative": [
      // "Difficult to understand",
      "Confusing Too complex",
      "Not visually appealing",
      // "Lacks information",
      // "Not well structured",
      "Inappropriate or harmful content",
      "Sexual or adult content",
      "Bug or technical issue",
      "Other",
    ],
  };
  void showFeedbackDialog(BuildContext mainContext) {
    try {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("Provide Feedback"),
            content: SizedBox(
              width: AppSizes.width(80),
              child: StatefulBuilder(
                builder: (context, setState) {
                  return SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Positive/Negative Selection
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Radio<String>(
                              value: "Positive",
                              groupValue: feedbackType,
                              onChanged: (value) {
                                setState(() {
                                  feedbackType = value;
                                  selectedFeedback = null;
                                  customFeedbackController.clear();
                                });
                              },
                            ),
                            const Text("Positive"),
                            const SizedBox(width: 20),
                            Radio<String>(
                              value: "Negative",
                              groupValue: feedbackType,
                              onChanged: (value) {
                                setState(() {
                                  feedbackType = value;
                                  selectedFeedback = null;
                                  customFeedbackController.clear();
                                });
                              },
                            ),
                            const Text("Negative"),
                          ],
                        ),

                        // Feedback Options
                        ...feedbackOptions[feedbackType]!.map((option) {
                          return RadioListTile<String>(
                            title: Text(option),
                            value: option,
                            groupValue: selectedFeedback,
                            onChanged: (value) {
                              setState(() {
                                selectedFeedback = value;
                                if (value != "Other") {
                                  customFeedbackController.clear();
                                }
                              });
                            },
                          );
                        }).toList(),

                        // Show TextField if "Other" is selected
                        if (selectedFeedback == "Other")
                          Padding(
                            padding: const EdgeInsets.only(top: 10.0),
                            child: TextField(
                              controller: customFeedbackController,
                              decoration: InputDecoration(
                                labelText: "Your feedback",
                                border: OutlineInputBorder(),
                                hintText: "Enter your feedback here...",
                              ),
                              maxLines: 3,
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () async {
                  String finalFeedback = selectedFeedback == "Other"
                      ? customFeedbackController.text
                      : selectedFeedback ?? "";

                  if (finalFeedback.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text("Please provide feedback."),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                                     setState(() {
                     isStarred = true;
                   });

                   await ApiService.submitFeedback(
                     feedbackType: feedbackType!,
                     selectedFeedback: selectedFeedback ?? finalFeedback,
                     customFeedback: selectedFeedback == "Other"
                         ? customFeedbackController.text
                         : null,
                   );

                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text("Thank You!"),
                        content: const Text(
                          "Your feedback has been submitted.",
                        ),
                      );
                    },
                  );

                  // Close dialog after 1.5 seconds
                  Future.delayed(const Duration(seconds: 1), () {
                    Navigator.of(context).pop(); // Close Thank You dialog
                    Navigator.of(context).pop(); // Close original dialog
                  });
                },
                child: const Text("Submit"),
              ),
            ],
          );
        },
      );
    } catch (e) {
      print("Error showing feedback dialog: $e");
      Navigator.of(context).pop(); // Close original feedback dialog
    }
  }

  @override
  Widget build(BuildContext context) {
    double size = widget.size;
    IconData icon = widget.icon;
    final buildContext = widget.mainContext;
    return GestureDetector(
      onTap: () {
        showFeedbackDialog(buildContext);
      },
      child: Row(
        children: [
          widget.isShowText
              ? Text(
                  "Feedback",
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w800,
                  ),
                  // GoogleFonts.nunitoSans(
                  // ),
                )
              : Container(),
          Container(
            // width: SizeConfig.blockSizeHorizontal * size,
            // height: SizeConfig.blockSizeHorizontal * size,
            // padding: EdgeInsets.all(8),
            padding: EdgeInsets.all(AppSizes.width(1)),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(30)),
            child: Center(
              child: Icon(icon, color: Colors.white, size: size),
            ),
          ),
        ],
      ),
    );
  }
}
