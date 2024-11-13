class SipAccount {
  late String webSocketUrl;
  late String uri;
  late String authorizationUser;
  late String password;
  late String displayName;
  late String userAgent;
  late String host;

  SipAccount({
    required this.webSocketUrl,
    required this.uri,
    required this.authorizationUser,
    required this.password,
    required this.displayName,
    required this.userAgent,
    required this.host,
  });

  SipAccount.empty() {
    webSocketUrl = '';
    uri = '';
    authorizationUser = '';
    password = '';
    displayName = '';
    userAgent = '';
    host = '';
  }

  Map<String, dynamic> toJson() {
    return {
      'web_socket_url': webSocketUrl,
      'uri': uri,
      'authorization_user': authorizationUser,
      'password': password,
      'display_name': displayName,
      'user_agent': userAgent,
      'host': host,
    };
  }

  factory SipAccount.fromJson(Map<String, dynamic> map) {
    return SipAccount(
      webSocketUrl: map['web_socket_url'] as String,
      uri: map['uri'] as String,
      authorizationUser: map['authorization_user'] as String,
      password: map['password'] as String,
      displayName: map['display_name'] as String,
      userAgent: map['user_agent'] as String,
      host: map['host'] as String,
    );
  }
}
