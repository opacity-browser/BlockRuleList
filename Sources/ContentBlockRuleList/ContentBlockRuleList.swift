import Foundation
import WebKit
import TrackerRadarKit

public struct ContentBlockRuleList {
  
  let webView: WKWebView
  private let blockingRulesVersion = "1"
  private let trackerBlocklistVersion = "1"
  
  private var otherBlockRulesIdentifier: String {
    return "OtherContentBlockRules_v\(blockingRulesVersion)"
  }
  
  private var trackerBlockRulesIdentifier: String {
    return "ContentBlockRules_v\(trackerBlocklistVersion)"
  }
  
  public init(webView: WKWebView) {
    self.webView = webView
  }
  
  public func updateRules(isBlocking: Bool) {
    if isBlocking {
      removeOldVersions()
      addContentBlockingRules()
      addOtherBlockingRules()
    } else {
      self.webView.configuration.userContentController.removeAllContentRuleLists()
    }
  }
  
  private func removeOldVersions() {
    WKContentRuleListStore.default().getAvailableContentRuleListIdentifiers { identifiers in
      identifiers?.forEach { identifier in
        if identifier.hasPrefix("OtherContentBlockRules") && identifier != self.otherBlockRulesIdentifier {
          WKContentRuleListStore.default().removeContentRuleList(forIdentifier: identifier) { _ in
            print("Removed old rule: \(identifier)")
          }
        }
        if identifier.hasPrefix("ContentBlockRules") && identifier != self.trackerBlockRulesIdentifier {
          WKContentRuleListStore.default().removeContentRuleList(forIdentifier: identifier) { _ in
            print("Removed old rule: \(identifier)")
          }
        }
        
        if identifier == "OtherContentBlockRules" {
          WKContentRuleListStore.default().removeContentRuleList(forIdentifier: "OtherContentBlockRules") { _ in
            print("Removed old rule: OtherContentBlockRules")
          }
        }
        
        if identifier == "ContentBlockRules" {
          WKContentRuleListStore.default().removeContentRuleList(forIdentifier: "ContentBlockRules") { _ in
            print("Removed old rule: ContentBlockRules")
          }
        }
      }
    }
  }
  
  private func addOtherBlockingRules() {
    if let rulePath = Bundle.module.path(forResource: "blockingRules", ofType: "json"),
       let ruleString = try? String(contentsOfFile: rulePath) {
      WKContentRuleListStore.default().compileContentRuleList(
        forIdentifier: otherBlockRulesIdentifier,
        encodedContentRuleList: ruleString
      ) { result, error in
        if let result = result {
          self.webView.configuration.userContentController.add(result)
          print("Add other tracker blocking - identifier: \(self.otherBlockRulesIdentifier)")
        }
      }
    }
  }
  
  private func addContentBlockingRules() {
    WKContentRuleListStore.default().lookUpContentRuleList(forIdentifier: trackerBlockRulesIdentifier) { result, error in
      if let result = result {
        self.webView.configuration.userContentController.add(result)
        print("Add tracker blocking from cache - identifier: \(self.trackerBlockRulesIdentifier)")
      } else {
        print("Cache miss for \(self.trackerBlockRulesIdentifier)")
        self.addBlockingRules()
      }
    }
  }
  
  private func addBlockingRules() {
    if let rulePath = Bundle.module.path(forResource: "duckduckgoTrackerBlocklists", ofType: "json") {
      do {
        let ruleData = try Data(contentsOf: URL(fileURLWithPath: rulePath))
        let tds = try JSONDecoder().decode(TrackerData.self, from: ruleData)
        let builder = ContentBlockerRulesBuilder(trackerData: tds)
        let rules = builder.buildRules(withExceptions: [], andTemporaryUnprotectedDomains: [], andTrackerAllowlist: [])
        let data = try JSONEncoder().encode(rules)
        let ruleList = String(data: data, encoding: .utf8)!
        
        WKContentRuleListStore.default().compileContentRuleList(
          forIdentifier: trackerBlockRulesIdentifier,
          encodedContentRuleList: ruleList
        ) { result, error in
          if let result = result {
            self.webView.configuration.userContentController.add(result)
            print("Add tracker blocking - identifier: \(self.trackerBlockRulesIdentifier)")
          }
        }
      } catch {
        print("Error loading or decoding tracker data: \(error)")
      }
    }
  }
}
