////
///  PostDetailGenerator.swift
//

public final class PostDetailGenerator: StreamGenerator {

    public var currentUser: User?
    public var streamKind: StreamKind
    weak public var destination: StreamDestination?

    private var post: Post?
    private let postParam: String
    private var localToken: String!
    private var loadingToken = LoadingToken()

    public init(currentUser: User?,
         postParam: String,
         post: Post?,
         streamKind: StreamKind,
         destination: StreamDestination
        ) {
        self.currentUser = currentUser
        self.post = post
        self.postParam = postParam
        self.streamKind = streamKind
        self.localToken = loadingToken.resetInitialPageLoadingToken()
        self.destination = destination
    }

    public func bind() {
        localToken = loadingToken.resetInitialPageLoadingToken()
        setPlaceHolders()
        setInitialPost()
        loadPost()
        loadPostComments()
        loadPostLovers()
        loadPostReposters()
    }

}

private extension PostDetailGenerator {

    func setPlaceHolders() {
        destination?.setPlaceholders([
            StreamCellItem(type: .Placeholder, placeholderType: .PostHeader),
            StreamCellItem(type: .Placeholder, placeholderType: .PostLovers),
            StreamCellItem(type: .Placeholder, placeholderType: .PostReposters),
            StreamCellItem(type: .Placeholder, placeholderType: .PostComments)
        ])
    }

    func setInitialPost() {
        guard let post = post else { return }

        destination?.setPrimaryJSONAble(post)
        if post.content?.count > 0 {
            let postItems = parse([post])
            destination?.replacePlaceholder(.PostHeader, items: postItems)
        }
    }

    func loadPost() {
        // load the post with no comments
        PostService().loadPost(
            postParam,
            needsComments: false,
            success: { [weak self] (post, responseConfig) in
                guard let sself = self else { return }
                guard sself.loadingToken.isValidInitialPageLoadingToken(sself.localToken) else { return }
                sself.post = post
                // TODO: make sure this responseConfig is what we want. We might want to use the comments response config
                sself.destination?.setPagingConfig(responseConfig)
                sself.destination?.setPrimaryJSONAble(post)
                let postItems = sself.parse([post])
                sself.destination?.replacePlaceholder(.PostHeader, items: postItems)
            },
            failure: { [weak self] _ in
                guard let sself = self else { return }
                sself.destination?.primaryJSONAbleNotFound()
        })
    }

    func loadPostComments() {
        guard loadingToken.isValidInitialPageLoadingToken(localToken) else { return }
        PostService().loadPostComments(
            postParam,
            success: { [weak self] (comments, responseConfig) in
                guard let sself = self else { return }
                guard sself.loadingToken.isValidInitialPageLoadingToken(sself.localToken) else { return }
                let commentItems = sself.parse(comments)
                sself.destination?.replacePlaceholder(.PostComments, items: commentItems)
            },
            failure: { _ in
                print("failed load post comments")
        })
    }

    func loadPostLovers() {
        guard loadingToken.isValidInitialPageLoadingToken(localToken) else { return }
        PostService().loadPostLovers(
            postParam,
            success: { [weak self] (users, _) in
                guard let sself = self else { return }
                guard sself.loadingToken.isValidInitialPageLoadingToken(sself.localToken) else { return }
                guard users.count > 0 else { return }

                let loversItems = sself.userAvatarCellItems(
                    users,
                    icon: .Heart,
                    seeMoreTitle: InterfaceString.Post.LovedByList
                )
                sself.destination?.replacePlaceholder(.PostLovers, items: loversItems)
            },
            failure: { _ in
                print("failed load post lovers")
        })
    }

    func loadPostReposters() {
        guard loadingToken.isValidInitialPageLoadingToken(localToken) else { return }
        PostService().loadPostReposters(
            postParam,
            success: { [weak self] (users, _) in
                guard let sself = self else { return }
                guard sself.loadingToken.isValidInitialPageLoadingToken(sself.localToken) else { return }
                guard users.count > 0 else { return }

                let repostersItems = sself.userAvatarCellItems(
                    users,
                    icon: .Repost,
                    seeMoreTitle: InterfaceString.Post.RepostedByList
                )
                sself.destination?.replacePlaceholder(.PostReposters, items: repostersItems)
            },
            failure: { _ in
                print("failed load post reposters")
        })
    }

    func userAvatarCellItems(
        users: [User],
        icon: InterfaceImage,
        seeMoreTitle: String) -> [StreamCellItem]
    {
        let model = UserAvatarCellModel(icon: icon, seeMoreTitle: seeMoreTitle)
        model.users = users

        return [
            StreamCellItem(jsonable: JSONAble.fromJSON([:], fromLinked: false), type: .Spacer(height: 4.0)),
            StreamCellItem(jsonable: model, type: .UserAvatars)
        ]
    }
}
