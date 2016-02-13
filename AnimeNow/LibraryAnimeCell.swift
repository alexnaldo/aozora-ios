//
//  AnimeLibraryCell.swift
//  Aozora
//
//  Created by Paul Chavarria Podoliako on 7/2/15.
//  Copyright (c) 2015 AnyTap. All rights reserved.
//

import Foundation
import ANCommonKit

protocol AnimeLibraryCellDelegate: class {
    func cellPressedWatched(cell: AnimeLibraryCell, anime: Anime)
    func cellPressedEpisodeThread(cell: AnimeLibraryCell, anime: Anime, episode: Episode)
}
class AnimeLibraryCell: AnimeCell {
    
    weak var delegate: AnimeLibraryCellDelegate?
    var anime: Anime?
    weak var episode: Episode?
    var currentCancellationToken: NSOperation?
    
    @IBOutlet weak var userProgressLabel: UILabel!
    @IBOutlet weak var watchedButton: UIButton?
    @IBOutlet weak var commentButton: UIButton?
    @IBOutlet weak var episodeImageView: UIImageView?
    @IBOutlet weak var badgeButton: UIButton!
    
    @IBAction func watchedPressed(sender: AnyObject) {
        
        if let anime = anime, let progress = anime.progress ?? anime.publicProgress {
            
            progress.watchedEpisodes += 1
            progress.updatedEpisodes(anime.episodes)
            progress.saveInBackground()
            LibrarySyncController.updateAnime(progress)
        }
        
        delegate?.cellPressedWatched(self, anime:anime!)
        watchedButton?.animateBounce()
    }
    
    override func configureWithAnime(
        anime: Anime,
        canFadeImages: Bool = true,
        showEtaAsAired: Bool = false,
        showLibraryEta: Bool = false,
        publicAnime: Bool = false) {
        
            super.configureWithAnime(anime, canFadeImages: canFadeImages, showEtaAsAired: showEtaAsAired, showLibraryEta: showLibraryEta, publicAnime: publicAnime)
        
            self.anime = anime
        
            guard let progress = publicAnime ? anime.publicProgress : anime.progress else {
                return
            }

            userProgressLabel.text = "\(anime.type) · " + FontAwesome.Watched.rawValue + " \(progress.watchedEpisodes)/\(anime.episodes)   " + FontAwesome.Rated.rawValue + " \(progress.score)"
            
            if let episodeImageView = episodeImageView {
                if progress.myAnimeListList() == .Watching {
                    setEpisodeImageView(anime, nextEpisode: progress.watchedEpisodes)
                } else {
                    episodeImageView.setImageFrom(urlString: anime.fanartThumbURLString() ?? "")
                }
            }

            let title = FontAwesome.Watched.rawValue
            let aozoraList = AozoraList(rawValue: progress.list)!

            if aozoraList == .Completed || aozoraList == .Dropped || (progress.watchedEpisodes == anime.episodes && anime.episodes != 0) {
                watchedButton?.enabled = false
                watchedButton?.setTitle(title, forState: .Normal)
            } else {
                watchedButton?.enabled = true
                watchedButton?.setTitle("\(title) Ep \(progress.watchedEpisodes+1)", forState: .Normal)
            }

            // Setting the badge
            if let firstAired = anime.startDateTime ?? anime.startDate, let airingStatus = AnimeStatus(rawValue: anime.status)
                where aozoraList == .Watching {

                badgeButton.hidden = false

                let (etaString, status) = AiringController
                    .airingStatusForFirstAired(
                        firstAired,
                        currentEpisode: progress.watchedEpisodes,
                        totalEpisodes: anime.episodes,
                        airingStatus: airingStatus)

                    badgeButton.setTitle(etaString, forState: .Normal)
                switch status {
                case .Behind:
                    badgeButton.setBackgroundImage(UIImage(named: "badge-red"), forState: .Normal)
                case .Future:
                    badgeButton.setBackgroundImage(UIImage(named: "badge-green"), forState: .Normal)
                }

            } else {
                badgeButton.hidden = true
            }
    }
    
    func setEpisodeImageView(anime: Anime, nextEpisode: Int?) {
        
        if let cancelToken = currentCancellationToken {
            cancelToken.cancel()
        }
        
        let newCancelationToken = NSOperation()
        currentCancellationToken = newCancelationToken
        
        episodeImageView?.image = nil
        episode = nil
        anime.episodeList().continueWithExecutor(BFExecutor.mainThreadExecutor(), withSuccessBlock: { (task: BFTask!) -> AnyObject! in
            
            if newCancelationToken.cancelled {
                return nil
            }
            
            guard let episodes = task.result as? [Episode],
                let nextEpisode = nextEpisode where episodes.count > nextEpisode else {
                    self.episodeImageView?.setImageFrom(urlString: anime.fanart ?? anime.imageUrl ?? "")
                    return nil
            }
            
            let episode = episodes[nextEpisode]
            self.episode = episode
            self.episodeImageView?.setImageFrom(urlString: episode.imageURLString())
            
            return nil
        })
    }
    
    // MARK: - IBActions
    
    @IBAction func pressedEpisodeImageView(sender: AnyObject) {
        if let episode = episode {
            delegate?.cellPressedEpisodeThread(self, anime: episode.anime, episode: episode)
        }
    }

}