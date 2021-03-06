////
///  StreamCellItemParserSpec.swift
//

import Ello
import Quick
import Nimble
import Moya


class StreamCellItemParserSpec: QuickSpec {
    override func spec() {
        describe("StreamCellItemParser") {

            var subject = StreamCellItemParser()

            describe("-streamCellItems:") {

                beforeEach {
                    subject = StreamCellItemParser()
                }

                it("returns an empty array if an empty array of Posts is passed in") {
                    let posts = [Post]()
                    expect(subject.parse(posts, streamKind: .Following).count) == 0
                }

                it("returns an empty array if an empty array of Comments is passed in") {
                    let comments = [ElloComment]()
                    expect(subject.parse(comments, streamKind: .Following).count) == 0
                }

                it("returns an array with the proper count of stream cell items when parsing friends.json's posts") {
                    var cellItems = [StreamCellItem]()
                    StreamService().loadStream(ElloAPI.FriendStream, streamKind: nil,
                        success: { (jsonables, responseConfig) in
                            cellItems = subject.parse(jsonables, streamKind: .Following)
                        },
                        failure: nil
                    )
                    expect(cellItems.count) == 8
                }

                it("returns an empty array if an empty array of Activities is passed in") {
                    let activities = [Notification]()
                    expect(subject.parse(activities, streamKind: .Notifications(category: nil)).count) == 0
                }

                it("returns an array with the proper count of stream cell items when parsing friends.json's activities") {
                    var loadedNotifications = [StreamCellItem]()
                    StreamService().loadStream(ElloAPI.NotificationsStream(category: nil), streamKind: nil,
                        success: { (jsonables, responseConfig) in
                            loadedNotifications = subject.parse(jsonables, streamKind: .Notifications(category: nil))
                        },
                        failure: nil
                    )
                    expect(loadedNotifications.count) == 14
                }
            }
        }
    }
}
