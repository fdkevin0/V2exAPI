import Foundation

/// V2ex API
public struct V2exAPI {
  
  /**
   个人访问令牌
   
   生成参考： https://v2ex.com/help/personal-access-token
   */
  public var accessToken: String?
  
  private let endpointV1 = "https://v2ex.com/api/"
  private let endpointV2 = "https://www.v2ex.com/api/v2/"
  
  public init(accessToken: String? = nil) {
    self.accessToken = accessToken
  }
  
  /**
   HTTP 请求
   */
  private func request<T>(httpMethod: String = "GET", url: String, args: [String: String]? = nil, decodeClass: T.Type) async throws -> (
    T?, URLResponse?
  ) where T : Decodable {
    let urlComponents = NSURLComponents(string: url)!
    
    if args != nil {
      urlComponents.queryItems =
      args?.map({ (k, v) in
        return NSURLQueryItem(name: k, value: v)
      }) as [URLQueryItem]?
    }
    
    guard let requestUrl = urlComponents.url else {
      return (nil, nil)
    }
    
    var request = URLRequest(url: requestUrl)
    request.httpMethod = httpMethod
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    
    if let accessToken = accessToken {
      request.setValue("Bearer " + accessToken, forHTTPHeaderField: "Authorization")
    }
    let (data, response) = try await URLSession.shared.data(for: request)
    
    let decoder = JSONDecoder()
    
    let obj = try decoder.decode(decodeClass.self, from: data)
    
    return (obj, response)
  }
  
  
  // =========== Others ===========
  
  /**
   获取节点列表
   */
  public func nodesList() async throws -> [V2Node]? {
    let (data, _) = try await request(
      url: endpointV1 + "nodes/list.json",
      args: [
        "fields": "id,name,title,topics,aliases",
        "sort_by": "topics",
        "reverse": "1",
      ],
      decodeClass: [V2Node].self
    )
    return data;
  }
  
  // =========== V1 ===========
  
  /**
   最热主题
   
   相当于首页右侧的 10 大每天的内容。
   */
  public func hotTopics() async throws -> [V2Topic]? {
    let (data, _) = try await request(
      url: endpointV1 + "topics/hot.json",
      decodeClass: [V2Topic].self
    )
    return data
  }
  
  /**
   最新主题
   
   相当于首页的“全部”这个 tab 下的最新内容。
   */
  public func latestTopics() async throws -> [V2Topic]? {
    let (data, _) = try await request(
      url: endpointV1 + "topics/latest.json",
      decodeClass: [V2Topic].self
    )
    return data
  }
  
  /**
   节点信息
   
   获得指定节点的名字，简介，URL 及头像图片的地址。
   
   - parameter  name: 节点名（V2EX 的节点名全是半角英文或者数字）
   */
  public func nodesShow(name: String) async throws -> V2Node? {
    let (data, _) = try await request(
      url: endpointV1 + "nodes/show.json",
      args: [
        "name": name
      ],
      decodeClass: V2Node.self
    )
    return data;
  }
  
  /**
   用户主页
   
   获得指定用户的自我介绍，及其登记的社交网站信息。
   
   - parameter  username: 用户名
   - parameter  id: 用户在 V2EX 的数字 ID
   */
  public func memberShow(username: String? = nil, id: Int? = nil) async throws -> V2Member? {
    var args:[String:String] = [:]
    if let username = username {
      args["username"] = username;
    }
    if let id = id {
      args["id"] = String(id);
    }
    
    if args.isEmpty {
      return nil
    }
    
    let (data, _) = try await request(
      url: endpointV1 + "members/show.json",
      args: args,
      decodeClass: V2Member.self
    )
    return data;
  }
  
  // =========== V2 ===========
  
  /**
   获取指定节点下的主题
   
   - parameter  nodeName: 节点名，如 "swift"
   - parameter  page: 分页页码，默认为 1
   */
  public func topics(nodeName: String, page: Int = 1) async throws -> V2Response<[V2Topic]?>? {
    let path = "nodes/\(nodeName)/topics"
    let (data, _) = try await request(
      url: endpointV2 + path,
      args: [
        "p": String(page)
      ],
      decodeClass: V2Response<[V2Topic]?>.self
    )
    return data
  }
  
  /**
   获取指定主题下的回复
   
   - parameter  topicId: 主题ID
   - parameter  page: 分页页码，默认为 1
   */
  public func replies(topicId: Int, page: Int = 1) async throws -> V2Response<[V2Comment]?>? {
    let path = "topics/\(topicId)/replies"
    let (data, _) = try await request(
      url: endpointV2 + path,
      args: [
        "p": String(page)
      ],
      decodeClass: V2Response<[V2Comment]?>.self
    )
    return data
  }
  
}
