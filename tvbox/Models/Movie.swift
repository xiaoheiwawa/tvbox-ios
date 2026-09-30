import Foundation

/// 电影/视频数据模型 - 对应 Android 版 Movie.java
struct Movie: Codable {
    /// 列表数据主体。
    var videoList: [Video] = []
    /// 总页数。
    var pagecount: Int = 0
    /// 当前页码。
    var page: Int = 0
    /// 总条数。
    var total: Int = 0
    /// 每页条数。
    var limit: Int = 0
    
    /// 单个视频条目
    struct Video: Codable, Identifiable, Hashable {
        /// 视频唯一 ID（接口可能返回 Int 或 String，见自定义解码）。
        var id: String
        /// 片名。
        var name: String = ""
        /// 海报地址。
        var pic: String = ""
        /// 备注（如“更新至第20集”）。
        var note: String = ""
        /// 年份。
        var year: String = ""
        /// 地区。
        var area: String = ""
        /// 类型/分类名。
        var type: String = ""
        /// 导演。
        var director: String = ""
        /// 演员。
        var actor: String = ""
        /// 简介。
        var des: String = ""
        /// 来源站点 key，用于跨源隔离收藏与历史。
        var sourceKey: String = ""
        /// 分类 ID。
        var tid: String = ""
        /// 最后更新时间。
        var last: String = ""
        /// 播放来源信息（部分接口会复用该字段）。
        var dt: String = ""
        
        init(id: String = UUID().uuidString, name: String = "", pic: String = "",
             note: String = "", sourceKey: String = "") {
            self.id = id
            self.name = name
            self.pic = pic
            self.note = note
            self.sourceKey = sourceKey
        }
        
        enum CodingKeys: String, CodingKey {
            case id = "vod_id"
            case name = "vod_name"
            case pic = "vod_pic"
            case note = "vod_remarks"
            case year = "vod_year"
            case area = "vod_area"
            case type = "type_name"
            case director = "vod_director"
            case actor = "vod_actor"
            case des = "vod_content"
            case tid = "type_id"
            case last = "vod_time"
            case dt = "vod_play_from"
            case sourceKey
        }
        
        /// 自定义解码以兼容多源字段类型差异（如 `vod_id` / `type_id` 可能是 Int 或 String）。
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            // 支持 String 或 Int 类型的 id
            if let intId = try? container.decode(Int.self, forKey: .id) {
                self.id = String(intId)
            } else {
                self.id = (try? container.decode(String.self, forKey: .id)) ?? UUID().uuidString
            }
            self.name = (try? container.decode(String.self, forKey: .name)) ?? ""
            self.pic = (try? container.decode(String.self, forKey: .pic)) ?? ""
            self.note = (try? container.decode(String.self, forKey: .note)) ?? ""
            self.year = (try? container.decode(String.self, forKey: .year)) ?? ""
            self.area = (try? container.decode(String.self, forKey: .area)) ?? ""
            self.type = (try? container.decode(String.self, forKey: .type)) ?? ""
            self.director = (try? container.decode(String.self, forKey: .director)) ?? ""
            self.actor = (try? container.decode(String.self, forKey: .actor)) ?? ""
            self.des = (try? container.decode(String.self, forKey: .des)) ?? ""
            self.tid = {
                if let intTid = try? container.decode(Int.self, forKey: .tid) {
                    return String(intTid)
                }
                return (try? container.decode(String.self, forKey: .tid)) ?? ""
            }()
            self.last = (try? container.decode(String.self, forKey: .last)) ?? ""
            self.dt = (try? container.decode(String.self, forKey: .dt)) ?? ""
            self.sourceKey = (try? container.decode(String.self, forKey: .sourceKey)) ?? ""
        }
    }
}

/// 播放地址解析结果。
///
/// 对应 Android/壳子端 `play` 接口的返回结构（hometv / drpy-node）：
/// `{"parse":0,"url":"https://.../index.m3u8","header":{...},"jx":0}`。
/// - `parse == 0`：`url` 即最终可直接播放的流地址。
/// - `parse == 1`：`url` 为需要嗅探/解析的页面地址，Swift 端暂不内置解析规则，
///   此时回退为原地址交由播放器直接尝试。
struct PlayResolution: Equatable {
    /// 最终播放地址。
    let url: String
    /// 0 表示直链，1 表示需要解析。
    let parse: Int
    /// 播放时需要携带的 HTTP 请求头（如 Referer / User-Agent）。
    let headers: [String: String]

    /// 是否已解析为可直接播放的直链。
    var isDirect: Bool { parse == 0 }

    /// 用于回退的原始结果。
    static func passthrough(url: String) -> PlayResolution {
        PlayResolution(url: url, parse: 1, headers: [:])
    }
}
