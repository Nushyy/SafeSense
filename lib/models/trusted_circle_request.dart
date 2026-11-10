class TrustedCircleRequest {
  final String id;
  final String requesterId;
  final String recipientId;
  final String status;
  final String? requesterName;
  final String? recipientName;

  TrustedCircleRequest({
    required this.id,
    required this.requesterId,
    required this.recipientId,
    required this.status,
    this.requesterName,
    this.recipientName,
  });

  factory TrustedCircleRequest.fromJson(
      Map<String, dynamic> json) {

    return TrustedCircleRequest(
      id: json['id'].toString(),

      requesterId:
          json['requester_id'],

      recipientId:
          json['recipient_id'],

      status:
          json['status'],

      requesterName:
          json['requester']?['full_name'],

      recipientName:
          json['recipient']?['full_name'],
    );
  }
}