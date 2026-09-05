/// 插件模型 — 存储插件元信息 + 源码
import 'dart:convert';
import 'spider_interface.dart';

class SpiderPlugin {
  final String id;
  String name;
  String description;
  String author;
  String version;
  PluginLanguage language;
  String sourceCode;
  String? entryFunction;    // 入口函数名 (默认 main)
  bool isBuiltIn;           // 是否内置
  bool isEnabled;           // 是否启用
  DateTime createdAt;
  DateTime updatedAt;
  Map<String, dynamic>? config;  // 插件配置
  List<String> tags;

  SpiderPlugin({
    required this.id,
    required this.name,
    this.description = '',
    this.author = '',
    this.version = '1.0.0',
    this.language = PluginLanguage.javascript,
    required this.sourceCode,
    this.entryFunction,
    this.isBuiltIn = false,
    this.isEnabled = true,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.config,
    this.tags = const [],
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// 从 JSON 创建
  factory SpiderPlugin.fromJson(Map<String, dynamic> json) => SpiderPlugin(
    id: json['id'] ?? '',
    name: json['name'] ?? '',
    description: json['description'] ?? '',
    author: json['author'] ?? '',
    version: json['version'] ?? '1.0.0',
    language: PluginLanguage.values.firstWhere(
      (l) => l.name == json['language'],
      orElse: () => PluginLanguage.javascript,
    ),
    sourceCode: json['sourceCode'] ?? '',
    entryFunction: json['entryFunction'],
    isBuiltIn: json['isBuiltIn'] ?? false,
    isEnabled: json['isEnabled'] ?? true,
    createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
    updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    config: json['config'],
    tags: json['tags'] != null ? List<String>.from(json['tags']) : [],
  );

  /// 序列化为 JSON
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'author': author,
    'version': version,
    'language': language.name,
    'sourceCode': sourceCode,
    'entryFunction': entryFunction,
    'isBuiltIn': isBuiltIn,
    'isEnabled': isEnabled,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'config': config,
    'tags': tags,
  };

  /// 导出为字符串
  String export() => jsonEncode(toJson());

  /// 从字符串导入
  factory SpiderPlugin.import(String json) =>
      SpiderPlugin.fromJson(jsonDecode(json));

  /// 生成模板代码
  static String template(PluginLanguage lang) {
    switch (lang) {
      case PluginLanguage.javascript:
        return _jsTemplate;
      case PluginLanguage.python:
        return _pythonTemplate;
      case PluginLanguage.php:
        return _phpTemplate;
      case PluginLanguage.go:
        return _goTemplate;
      case PluginLanguage.java:
        return _javaTemplate;
    }
  }

  SpiderPlugin copyWith({String? name, String? sourceCode, bool? isEnabled}) =>
    SpiderPlugin(
      id: id, name: name ?? this.name, description: description,
      author: author, version: version, language: language,
      sourceCode: sourceCode ?? this.sourceCode,
      entryFunction: entryFunction, isBuiltIn: isBuiltIn,
      isEnabled: isEnabled ?? this.isEnabled,
      createdAt: createdAt, updatedAt: DateTime.now(),
      config: config, tags: tags,
    );
}

// ════════════════════════════════════════
//  各语言模板代码
// ════════════════════════════════════════

const _jsTemplate = r'''// ═══ AllPlay Spider Plugin (JavaScript) ═══
// 可用 API:
//   http.get(url, headers)  → { "status":200, "body":"..." }
//   http.post(url, data, headers)
//   html.parse(htmlStr)     → DOM 查询
//   JSON.stringify(obj)
//   log(message)            // 控制台输出
//   sleep(ms)               // 异步等待

const API = "https://your-api.com/api.php/provide/vod/";

// 搜索
async function search(keyword, page = 1) {
    const url = `${API}?ac=detail&wd=${encodeURIComponent(keyword)}&pg=${page}`;
    const res = await http.get(url);
    const json = JSON.parse(res.body);
    return JSON.stringify({
        list: (json.list || []).map(item => ({
            id: item.vod_id,
            title: item.vod_name,
            cover: item.vod_pic,
            desc: item.vod_content,
            category: item.type_name,
            tags: [item.vod_year, item.vod_area, item.vod_remarks].filter(Boolean),
        }))
    });
}

// 详情
async function detail(url) {
    const res = await http.get(url);
    const json = JSON.parse(res.body);
    const vod = (json.list || [])[0] || {};
    return JSON.stringify({
        id: vod.vod_id,
        title: vod.vod_name,
        cover: vod.vod_pic,
        desc: vod.vod_content,
        category: vod.type_name,
        episodes: parsePlayUrl(vod.vod_play_url || ''),
    });
}

// 分类
async function category(categoryId, page = 1) {
    const url = `${API}?ac=detail&pg=${page}` + (categoryId ? `&t=${categoryId}` : '');
    const res = await http.get(url);
    const json = JSON.parse(res.body);
    return JSON.stringify({
        list: (json.list || []).map(item => ({
            id: item.vod_id,
            title: item.vod_name,
            cover: item.vod_pic,
            category: item.type_name,
        })),
        categories: (json.class || []).map(c => ({ id: c.type_id, name: c.type_name })),
    });
}

// 播放解析
async function playerUrl(url, headers = {}) {
    return JSON.stringify({ url, headers });
}

// 直播
async function liveList(url) {
    const res = await http.get(url);
    const lines = res.body.split('\n');
    const channels = [];
    for (let i = 0; i < lines.length; i++) {
        if (lines[i].startsWith('#EXTINF:')) {
            const name = lines[i].split(',').pop().trim();
            const streamUrl = (lines[i + 1] || '').trim();
            if (streamUrl.startsWith('http')) {
                channels.push({ name, url: streamUrl, group: '直播' });
            }
        }
    }
    return JSON.stringify({ channels });
}

// 工具: 解析播放链接
function parsePlayUrl(str) {
    if (!str) return [];
    const groups = str.split('$$$');
    const episodes = [];
    for (const group of groups) {
        for (const part of group.split('#')) {
            if (part.includes('$')) {
                const [name, url] = part.split('$');
                episodes.push({ name: name.trim(), url: url?.trim() || '' });
            }
        }
    }
    return episodes;
}

// 测试
async function test() {
    const res = await search('三体');
    const data = JSON.parse(res);
    log(`搜索到 ${(data.list || []).length} 个结果`);
    return data.list && data.list.length > 0;
}
''';

const _pythonTemplate = r'''# ═══ AllPlay Spider Plugin (Python) ═══
# 可用 API:
#   http_get(url, headers)   → { "status":200, "body":"..." }
#   http_post(url, data, headers)
#   html_parse(html_str)     → DOM 查询
#   log(message)             # 控制台输出
#   json.dumps(obj)          # JSON 序列化

import json

API = "https://your-api.com/api.php/provide/vod/"

def search(keyword, page=1):
    """搜索内容"""
    url = f"{API}?ac=detail&wd={keyword}&pg={page}"
    res = http_get(url)
    data = json.loads(res["body"])
    return json.dumps({
        "list": [
            {
                "id": item.get("vod_id"),
                "title": item.get("vod_name", ""),
                "cover": item.get("vod_pic", ""),
                "desc": item.get("vod_content", ""),
                "category": item.get("type_name", ""),
                "tags": [item.get("vod_year"), item.get("vod_area"), item.get("vod_remarks")],
            }
            for item in data.get("list", [])
        ]
    })

def detail(url):
    """获取详情"""
    res = http_get(url)
    data = json.loads(res["body"])
    vod = data.get("list", [{}])[0]
    return json.dumps({
        "id": vod.get("vod_id"),
        "title": vod.get("vod_name", ""),
        "cover": vod.get("vod_pic", ""),
        "desc": vod.get("vod_content", ""),
        "episodes": parse_play_url(vod.get("vod_play_url", "")),
    })

def category(category_id=None, page=1):
    """分类列表"""
    url = f"{API}?ac=detail&pg={page}"
    if category_id:
        url += f"&t={category_id}"
    res = http_get(url)
    data = json.loads(res["body"])
    return json.dumps({
        "list": [
            {"id": item.get("vod_id"), "title": item.get("vod_name"), "cover": item.get("vod_pic")}
            for item in data.get("list", [])
        ],
        "categories": [
            {"id": c.get("type_id"), "name": c.get("type_name")}
            for c in data.get("class", [])
        ],
    })

def player_url(url, headers=None):
    """解析播放地址"""
    return json.dumps({"url": url, "headers": headers or {}})

def live_list(url):
    """直播源"""
    res = http_get(url)
    channels = []
    lines = res["body"].split("\n")
    for i, line in enumerate(lines):
        if line.startswith("#EXTINF:"):
            name = line.split(",")[-1].strip()
            stream_url = lines[i + 1].strip() if i + 1 < len(lines) else ""
            if stream_url.startswith("http"):
                channels.append({"name": name, "url": stream_url, "group": "直播"})
    return json.dumps({"channels": channels})

def parse_play_url(s):
    """解析播放链接"""
    episodes = []
    for group in s.split("$$$"):
        for part in group.split("#"):
            if "$" in part:
                name, url = part.split("$", 1)
                episodes.append({"name": name.strip(), "url": url.strip()})
    return episodes

def test():
    """测试插件"""
    data = json.loads(search("三体"))
    count = len(data.get("list", []))
    log(f"搜索到 {count} 个结果")
    return count > 0
''';

const _phpTemplate = r'''<?php
// ═══ AllPlay Spider Plugin (PHP) ═══
// 可用 API:
//   http_get($url, $headers)   → [status, body]
//   http_post($url, $data, $headers)
//   html_parse($html)          → DOM 查询
//   log($message)

$API = "https://your-api.com/api.php/provide/vod/";

function search($keyword, $page = 1) {
    global $API;
    $url = $API . "?ac=detail&wd=" . urlencode($keyword) . "&pg=" . $page;
    $res = http_get($url);
    $json = json_decode($res[1], true);
    $list = [];
    foreach ($json['list'] ?? [] as $item) {
        $list[] = [
            'id' => $item['vod_id'] ?? '',
            'title' => $item['vod_name'] ?? '',
            'cover' => $item['vod_pic'] ?? '',
            'desc' => $item['vod_content'] ?? '',
            'category' => $item['type_name'] ?? '',
            'tags' => array_filter([$item['vod_year'] ?? '', $item['vod_area'] ?? '', $item['vod_remarks'] ?? '']),
        ];
    }
    return json_encode(['list' => $list]);
}

function detail($url) {
    $res = http_get($url);
    $json = json_decode($res[1], true);
    $vod = $json['list'][0] ?? [];
    return json_encode([
        'id' => $vod['vod_id'] ?? '',
        'title' => $vod['vod_name'] ?? '',
        'cover' => $vod['vod_pic'] ?? '',
        'desc' => $vod['vod_content'] ?? '',
        'episodes' => parse_play_url($vod['vod_play_url'] ?? ''),
    ]);
}

function category($category_id = null, $page = 1) {
    global $API;
    $url = $API . "?ac=detail&pg=" . $page;
    if ($category_id) $url .= "&t=" . $category_id;
    $res = http_get($url);
    $json = json_decode($res[1], true);
    $list = [];
    foreach ($json['list'] ?? [] as $item) {
        $list[] = ['id' => $item['vod_id'], 'title' => $item['vod_name'], 'cover' => $item['vod_pic']];
    }
    $cats = [];
    foreach ($json['class'] ?? [] as $c) {
        $cats[] = ['id' => $c['type_id'], 'name' => $c['type_name']];
    }
    return json_encode(['list' => $list, 'categories' => $cats]);
}

function player_url($url, $headers = []) {
    return json_encode(['url' => $url, 'headers' => $headers]);
}

function live_list($url) {
    $res = http_get($url);
    $channels = [];
    $lines = explode("\n", $res[1]);
    for ($i = 0; $i < count($lines); $i++) {
        if (str_starts_with($lines[$i], '#EXTINF:')) {
            $parts = explode(',', $lines[$i]);
            $name = end($parts);
            $stream_url = $lines[$i + 1] ?? '';
            if (str_starts_with($stream_url, 'http')) {
                $channels[] = ['name' => trim($name), 'url' => trim($stream_url), 'group' => '直播'];
            }
        }
    }
    return json_encode(['channels' => $channels]);
}

function parse_play_url($str) {
    $episodes = [];
    foreach (explode('$$$', $str) as $group) {
        foreach (explode('#', $group) as $part) {
            if (str_contains($part, '$')) {
                [$name, $url] = explode('$', $part, 2);
                $episodes[] = ['name' => trim($name), 'url' => trim($url)];
            }
        }
    }
    return $episodes;
}

function test() {
    $data = json_decode(search('三体'), true);
    $count = count($data['list'] ?? []);
    log("搜索到 {$count} 个结果");
    return $count > 0;
}
''';

const _goTemplate = r'''// ═══ AllPlay Spider Plugin (Go) ═══
package main

import (
    "encoding/json"
    "net/url"
)

var API = "https://your-api.com/api.php/provide/vod/"

type VideoItem struct {
    ID       string   `json:"id"`
    Title    string   `json:"title"`
    Cover    string   `json:"cover"`
    Desc     string   `json:"desc"`
    Category string   `json:"category"`
    Tags     []string `json:"tags"`
}

type Episode struct {
    Name string `json:"name"`
    URL  string `json:"url"`
}

func search(keyword string, page int) string {
    apiUrl := fmt.Sprintf("%s?ac=detail&wd=%s&pg=%d", API, url.QueryEscape(keyword), page)
    res := httpGet(apiUrl, nil)
    var data map[string]interface{}
    json.Unmarshal([]byte(res["body"]), &data)

    list := []VideoItem{}
    if items, ok := data["list"].([]interface{}); ok {
        for _, item := range items {
            m := item.(map[string]interface{})
            list = append(list, VideoItem{
                ID:       fmt.Sprintf("%v", m["vod_id"]),
                Title:    fmt.Sprintf("%v", m["vod_name"]),
                Cover:    fmt.Sprintf("%v", m["vod_pic"]),
                Desc:     fmt.Sprintf("%v", m["vod_content"]),
                Category: fmt.Sprintf("%v", m["type_name"]),
            })
        }
    }
    result, _ := json.Marshal(map[string]interface{}{"list": list})
    return string(result)
}

func detail(url string) string {
    res := httpGet(url, nil)
    var data map[string]interface{}
    json.Unmarshal([]byte(res["body"]), &data)
    if items := data["list"].([]interface{}); len(items) > 0 {
        vod := items[0].(map[string]interface{})
        return fmt.Sprintf(`{"id":"%v","title":"%v","cover":"%v"}`,
            vod["vod_id"], vod["vod_name"], vod["vod_pic"])
    }
    return "{}"
}

func test() bool {
    data := json.loads(search("三体", 1))
    count := len(data["list"])
    log(fmt.Sprintf("搜索到 %d 个结果", count))
    return count > 0
}
''';

const _javaTemplate = r'''// ═══ AllPlay Spider Plugin (Java) ═══
import org.json.*;

public class Spider {
    private static final String API = "https://your-api.com/api.php/provide/vod/";

    // 搜索
    public static String search(String keyword, int page) throws Exception {
        String url = API + "?ac=detail&wd=" + URLEncoder.encode(keyword) + "&pg=" + page;
        String body = httpGet(url);
        JSONObject json = new JSONObject(body);
        JSONArray list = json.optJSONArray("list");
        JSONArray result = new JSONArray();
        if (list != null) {
            for (int i = 0; i < list.length(); i++) {
                JSONObject item = list.getJSONObject(i);
                JSONObject entry = new JSONObject();
                entry.put("id", item.optString("vod_id"));
                entry.put("title", item.optString("vod_name"));
                entry.put("cover", item.optString("vod_pic"));
                entry.put("desc", item.optString("vod_content"));
                entry.put("category", item.optString("type_name"));
                result.put(entry);
            }
        }
        return new JSONObject().put("list", result).toString();
    }

    // 详情
    public static String detail(String url) throws Exception {
        String body = httpGet(url);
        JSONObject json = new JSONObject(body);
        JSONArray list = json.optJSONArray("list");
        if (list != null && list.length() > 0) {
            JSONObject vod = list.getJSONObject(0);
            JSONObject result = new JSONObject();
            result.put("id", vod.optString("vod_id"));
            result.put("title", vod.optString("vod_name"));
            result.put("cover", vod.optString("vod_pic"));
            result.put("desc", vod.optString("vod_content"));
            return result.toString();
        }
        return "{}";
    }

    // 测试
    public static boolean test() throws Exception {
        String data = search("三体", 1);
        JSONObject json = new JSONObject(data);
        int count = json.optJSONArray("list").length();
        log("搜索到 " + count + " 个结果");
        return count > 0;
    }
}
''';
