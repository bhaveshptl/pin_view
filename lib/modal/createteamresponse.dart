class CreateTeamResponse {
  final String name;
  final int resultCode;
  final int id;
  final Map<String, dynamic> placeholder;
  final String message;

  CreateTeamResponse({
    this.name,
    this.resultCode,
    this.id,
    this.placeholder,
    this.message,
  });

  factory CreateTeamResponse.fromJson(Map<String, dynamic> resJson) {
    return CreateTeamResponse(
      name: resJson["name"],
      resultCode: resJson["resultCode"],
      id: resJson["id"],
      placeholder: resJson["placeholder"],
      message: resJson["message"],
    );
  }
}
