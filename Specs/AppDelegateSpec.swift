////
///  AppDelegateSpec.swift
//

@testable import Ello
import Quick
import Nimble
import PINRemoteImage
import PINCache

class AppDelegateSpec: QuickSpec {
    override func spec() {
        describe("AppDelegate") {
            let subject = UIApplication.sharedApplication().delegate as? AppDelegate
            subject?.setupCaches()

            describe("caches") {

                describe("PINDiskCache") {

                    it("limits the size to 250 MB") {
                        expect(PINRemoteImageManager.sharedImageManager().cache.diskCache.byteLimit) == 250000000
                    }

                    it("has an object age of 2 weeks") {
                        expect(PINRemoteImageManager.sharedImageManager().cache.diskCache.ageLimit) == 1209600
                    }
                }
            }
        }
    }
}
