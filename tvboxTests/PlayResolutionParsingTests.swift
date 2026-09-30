#if os(iOS)
import Testing
@testable import TVBox

/// `SourceService.parsePlayResolution` 的纯解析测试。
///
/// 远程源（hometv / drpy-node）`?play=` 接口的返回结构在不同引擎间存在字段差异，
/// 这里覆盖已确认的几种形态，防止回归导致「点开播不了」。
@Suite("PlayResolution 解析")
struct PlayResolutionParsingTests {

    /// 标准直链形态：`parse=0` + `url`。
    @Test("直链结果解析")
    func parsesDirectURL() throws {
        let json = #"{"parse":0,"url":"https://cdn.example.com/live/index.m3u8","jx":0}"#
        let resolution = try #require(SourceService.parsePlayResolution(json))
        #expect(resolution.url == "https://cdn.example.com/live/index.m3u8")
        #expect(resolution.parse == 0)
        #expect(resolution.isDirect)
        #expect(resolution.headers.isEmpty)
    }

    /// 需要嗅探的形态：`parse=1`。
    @Test("嗅探结果解析")
    func parsesSniffURL() throws {
        let json = #"{"parse":1,"url":"http://api.example.com/api/zzxjj.php","jx":0}"#
        let resolution = try #require(SourceService.parsePlayResolution(json))
        #expect(resolution.url == "http://api.example.com/api/zzxjj.php")
        #expect(resolution.parse == 1)
        #expect(!resolution.isDirect)
    }

    /// 下发的请求头（对象形态）应被完整保留。
    @Test("请求头对象解析")
    func parsesHeaderObject() throws {
        let json = #"{"parse":0,"url":"https://a.com/x.m3u8","header":{"User-Agent":"okhttp/4.10.0","Referer":"https://tv.cctv.com/"}}"#
        let resolution = try #require(SourceService.parsePlayResolution(json))
        #expect(resolution.headers["User-Agent"] == "okhttp/4.10.0")
        #expect(resolution.headers["Referer"] == "https://tv.cctv.com/")
    }

    /// 请求头的 JSON 字符串形态也应被展开。
    @Test("请求头字符串解析")
    func parsesHeaderString() throws {
        let json = #"{"parse":0,"url":"https://a.com/x.m3u8","headers":"{\"Referer\":\"https://tv.cctv.com/\"}"}"#
        let resolution = try #require(SourceService.parsePlayResolution(json))
        #expect(resolution.headers["Referer"] == "https://tv.cctv.com/")
    }

    /// 兼容 `play_url` 字段名与字符串型 `parse`。
    @Test("兼容字段别名")
    func parsesAliases() throws {
        let json = #"{"parses":"1","play_url":"https://a.com/y.m3u8"}"#
        let resolution = try #require(SourceService.parsePlayResolution(json))
        #expect(resolution.url == "https://a.com/y.m3u8")
        #expect(resolution.parse == 1)
    }

    /// 缺少 url 时应返回 nil，交由调用方回退原地址。
    @Test("缺少 url 返回 nil")
    func returnsNilWhenURLMissing() {
        #expect(SourceService.parsePlayResolution(#"{"parse":0}"#) == nil)
        #expect(SourceService.parsePlayResolution("not json") == nil)
        #expect(SourceService.parsePlayResolution(#"{"url":""}"#) == nil)
    }
}
#endif
