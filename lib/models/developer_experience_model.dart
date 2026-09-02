/// A STAR-format story stored in the data_dev_stories table.
class DeveloperExperienceModel {
  final String id;
  final String title;
  final String categoryTag;
  final String situation;
  final String task;
  final String action;
  final String result;
  final String keyTakeaway;

  const DeveloperExperienceModel({
    required this.id,
    required this.title,
    required this.categoryTag,
    required this.situation,
    required this.task,
    required this.action,
    required this.result,
    required this.keyTakeaway,
  });

  factory DeveloperExperienceModel.fromDataDevStory(Map<String, dynamic> map) {
    return DeveloperExperienceModel(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      categoryTag: map['category_tag']?.toString() ?? 'Behavioral',
      situation: map['situation']?.toString() ?? '',
      task: map['task_description']?.toString() ?? '',
      action: map['action_taken']?.toString() ?? '',
      result: map['result_achieved']?.toString() ?? '',
      keyTakeaway: map['key_takeaway']?.toString() ?? '',
    );
  }
}
