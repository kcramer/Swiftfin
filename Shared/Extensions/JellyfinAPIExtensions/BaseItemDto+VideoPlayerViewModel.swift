//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Combine
import Defaults
import JellyfinAPI
import UIKit

extension BaseItemDto {
	func createVideoPlayerViewModel() -> AnyPublisher<VideoPlayerViewModel, Error> {
		let builder = DeviceProfileBuilder()
		// TODO: fix bitrate settings
		builder.setMaxBitrate(bitrate: 60_000_000)
		let profile = builder.buildProfile()

		let playbackInfo = PlaybackInfoDto(userId: SessionManager.main.currentLogin.user.id,
		                                   maxStreamingBitrate: 60_000_000,
		                                   startTimeTicks: self.userData?.playbackPositionTicks ?? 0,
		                                   deviceProfile: profile,
		                                   autoOpenLiveStream: true)

		return MediaInfoAPI.getPostedPlaybackInfo(itemId: self.id!,
		                                          userId: SessionManager.main.currentLogin.user.id,
		                                          maxStreamingBitrate: 60_000_000,
		                                          startTimeTicks: self.userData?.playbackPositionTicks ?? 0,
		                                          autoOpenLiveStream: true,
		                                          playbackInfoDto: playbackInfo)
			.map { response -> VideoPlayerViewModel in
				let mediaSource = response.mediaSources!.first!

				let audioStreams = mediaSource.mediaStreams?.filter { $0.type == .audio } ?? []
				let subtitleStreams = mediaSource.mediaStreams?.filter { $0.type == .subtitle } ?? []

				let defaultAudioStream = audioStreams.first(where: { $0.index! == mediaSource.defaultAudioStreamIndex! })

				let defaultSubtitleStream = subtitleStreams.first(where: { $0.index! == mediaSource.defaultSubtitleStreamIndex ?? -1 })

				// MARK: Stream

				var streamURL = URLComponents(string: SessionManager.main.currentLogin.server.currentURI)!

				let streamType: ServerStreamType

				if let transcodeURL = mediaSource.transcodingUrl {
					streamType = .transcode
					streamURL.path = transcodeURL
				} else {
					streamType = .direct
					streamURL.path = "/Videos/\(self.id!)/stream"
				}

				streamURL.addQueryItem(name: "Static", value: "true")
				streamURL.addQueryItem(name: "MediaSourceId", value: self.id!)
				streamURL.addQueryItem(name: "Tag", value: self.etag)
				streamURL.addQueryItem(name: "MinSegments", value: "6")

				// MARK: VidoPlayerViewModel Creation

				var subtitle: String?

				// MARK: Attach media content to self

				var modifiedSelfItem = self
				modifiedSelfItem.mediaStreams = mediaSource.mediaStreams

				// TODO: other forms of media subtitle
				if self.itemType == .episode {
					if let seriesName = self.seriesName, let episodeLocator = self.getEpisodeLocator() {
						subtitle = "\(seriesName) - \(episodeLocator)"
					}
				}

				let subtitlesEnabled = defaultSubtitleStream != nil

				let shouldShowAutoPlay = Defaults[.shouldShowAutoPlay] && itemType == .episode
				let autoplayEnabled = Defaults[.autoplayEnabled] && shouldShowAutoPlay

				let overlayType = Defaults[.overlayType]

				let shouldShowPlayPreviousItem = Defaults[.shouldShowPlayPreviousItem] && itemType == .episode
				let shouldShowPlayNextItem = Defaults[.shouldShowPlayNextItem] && itemType == .episode

				let videoPlayerViewModel = VideoPlayerViewModel(item: modifiedSelfItem,
				                                                title: modifiedSelfItem.name ?? "",
				                                                subtitle: subtitle,
				                                                streamURL: streamURL.url!,
				                                                streamType: streamType,
				                                                response: response,
				                                                audioStreams: audioStreams,
				                                                subtitleStreams: subtitleStreams,
				                                                selectedAudioStreamIndex: defaultAudioStream?.index ?? -1,
				                                                selectedSubtitleStreamIndex: defaultSubtitleStream?.index ?? -1,
				                                                subtitlesEnabled: subtitlesEnabled,
				                                                autoplayEnabled: autoplayEnabled,
				                                                overlayType: overlayType,
				                                                shouldShowPlayPreviousItem: shouldShowPlayPreviousItem,
				                                                shouldShowPlayNextItem: shouldShowPlayNextItem,
				                                                shouldShowAutoPlay: shouldShowAutoPlay)

				return videoPlayerViewModel
			}
			.eraseToAnyPublisher()
	}
}
