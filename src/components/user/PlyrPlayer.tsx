import React, { useRef, useEffect, useState } from 'react';
import { motion } from 'framer-motion';
import { X } from 'lucide-react';

interface PlyrPlayerProps {
  videoUrl: string;
  title: string;
  onClose: () => void;
  onOpen?: () => void;
}

export const PlyrPlayer: React.FC<PlyrPlayerProps> = ({ videoUrl, title, onClose, onOpen }) => {
  const playerRef = useRef<HTMLDivElement>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [playerInstance, setPlayerInstance] = useState<any>(null);
  const [isPlayerReady, setIsPlayerReady] = useState(false);

  // Extract video ID from YouTube URL
  const extractVideoId = (url: string): string => {
    const patterns = [
      /(?:youtube\.com\/watch\?v=|youtu\.be\/)([^&\n?#]+)/,
      /youtube\.com\/live\/([^&\n?#]+)/,
      /youtube\.com\/embed\/([^&\n?#]+)/
    ];
    
    for (const pattern of patterns) {
      const match = url.match(pattern);
      if (match) return match[1];
    }
    return '';
  };

  const videoId = extractVideoId(videoUrl);

  useEffect(() => {
    if (!videoId || !playerRef.current) return;

    let plyrPlayer: any = null;

    // Load Plyr CSS
    const plyrCSS = document.createElement('link');
    plyrCSS.rel = 'stylesheet';
    plyrCSS.href = 'https://cdn.plyr.io/3.7.8/plyr.css';
    document.head.appendChild(plyrCSS);

    // Load Plyr JS
    const plyrScript = document.createElement('script');
    plyrScript.src = 'https://cdn.plyr.io/3.7.8/plyr.polyfilled.js';
    plyrScript.onload = () => {
      initializePlayer();
    };
    document.head.appendChild(plyrScript);

    const initializePlayer = () => {
      if (!window.Plyr) return;

      const playerElement = playerRef.current?.querySelector('#plyr-player');
      if (!playerElement) return;

      // Enhanced Plyr configuration
      plyrPlayer = new window.Plyr('#plyr-player', {
        youtube: {
          noCookie: false,
          controls: 0,
          disablekb: 1,
          rel: 0,
          showinfo: 0,
          iv_load_policy: 3,
          modestbranding: 1,
          enablejsapi: 1
        },
        clickToPlay: true,
        hideControls: false,
        controls: [
          'play-large',
          'rewind',
          'play',
          'fast-forward',
          'progress',
          'current-time',
          'duration',
          'mute',
          'volume',
          'captions',
          'settings',
          'pip',
          'airplay',
          'fullscreen'
        ],
        settings: ['captions', 'quality', 'speed'],
        quality: {
          default: 720,
          options: [144, 240, 360, 480, 720, 1080, 1440, 2160],
          forced: true,
          onChange: (quality: number) => {
            console.log(`Quality changed to: ${quality}p`);
          }
        },
        speed: {
          selected: 1,
          options: [0.5, 0.75, 1, 1.25, 1.5, 1.75, 2]
        }
      });

      setPlayerInstance(plyrPlayer);

      // Enhanced event listeners
      plyrPlayer.on('ready', () => {
        console.log('Player ready');
        setIsLoading(false);
        setIsPlayerReady(true);
        onOpen?.();
        setupCustomControls();
      });

      plyrPlayer.on('playing', () => {
        console.log('Video playing');
      });

      plyrPlayer.on('pause', () => {
        console.log('Video paused');
      });

      // Handle page visibility change to prevent restart
      const handleVisibilityChange = () => {
        if (document.hidden) {
          // Page is hidden, pause the video
          if (plyrPlayer && plyrPlayer.playing) {
            plyrPlayer.pause();
          }
        }
      };

      document.addEventListener('visibilitychange', handleVisibilityChange);

      // Setup custom controls and click handlers
      const setupCustomControls = () => {
        // Center click handler with enhanced detection
        const centerClickLayer = playerRef.current?.querySelector('.center-click-layer');
        if (centerClickLayer) {
          centerClickLayer.addEventListener('click', function(e) {
            const rect = this.getBoundingClientRect();
            const centerX = rect.width / 2;
            const centerY = rect.height / 2;
            const clickX = e.clientX - rect.left;
            const clickY = e.clientY - rect.top;
            
            // Enhanced center detection with larger area
            if (Math.abs(clickX - centerX) < 150 && Math.abs(clickY - centerY) < 150) {
              e.preventDefault();
              e.stopPropagation();
              plyrPlayer.togglePlay();
            }
          });
        }

        // Double security for title and share areas
        const titleBlocker = playerRef.current?.querySelector('.title-blocker');
        const shareBlocker = playerRef.current?.querySelector('.share-blocker');
        
        if (titleBlocker) {
          titleBlocker.addEventListener('click', function(e) {
            e.preventDefault();
            e.stopPropagation();
            console.log('Title area click blocked');
          });
        }

        if (shareBlocker) {
          shareBlocker.addEventListener('click', function(e) {
            e.preventDefault();
            e.stopPropagation();
            console.log('Share area click blocked');
          });
        }
      };

      // Enhanced keyboard shortcuts
      const handleKeydown = (e: KeyboardEvent) => {
        const targetTagName = (e.target as HTMLElement).tagName.toLowerCase();
        if (targetTagName === 'input' || targetTagName === 'textarea') {
          return;
        }

        switch(e.key.toLowerCase()) {
          case ' ':
          case 'k':
            e.preventDefault();
            plyrPlayer.togglePlay();
            break;
          case 'f':
            e.preventDefault();
            plyrPlayer.fullscreen.toggle();
            break;
          case 'm':
            e.preventDefault();
            plyrPlayer.muted = !plyrPlayer.muted;
            break;
          case 'arrowleft':
            e.preventDefault();
            plyrPlayer.rewind(10);
            break;
          case 'arrowright':
            e.preventDefault();
            plyrPlayer.forward(10);
            break;
          case 'escape':
            e.preventDefault();
            onClose();
            break;
        }
      };

      document.addEventListener('keydown', handleKeydown);

      // Cleanup function
      return () => {
        document.removeEventListener('keydown', handleKeydown);
        document.removeEventListener('visibilitychange', handleVisibilityChange);
        if (plyrPlayer) {
          plyrPlayer.destroy();
        }
      };
    };

    return () => {
      // Enhanced cleanup
      if (plyrPlayer) {
        plyrPlayer.destroy();
        setPlayerInstance(null);
      }
      
      // Remove scripts and styles
      const existingScript = document.querySelector('script[src="https://cdn.plyr.io/3.7.8/plyr.polyfilled.js"]');
      const existingCSS = document.querySelector('link[href="https://cdn.plyr.io/3.7.8/plyr.css"]');
      if (existingScript) existingScript.remove();
      if (existingCSS) existingCSS.remove();
    };
  }, [videoId, onClose]);

  // Handle escape key for closing
  useEffect(() => {
    const handleEscape = (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        onClose();
      }
    };

    document.addEventListener('keydown', handleEscape);
    return () => document.removeEventListener('keydown', handleEscape);
  }, [onClose]);

  if (!videoId) {
    return (
      <motion.div
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        exit={{ opacity: 0 }}
        className="fixed inset-0 bg-black/95 backdrop-blur-sm z-[70] flex items-center justify-center"
      >
        <div className="text-white text-center">
          <p>Invalid video URL</p>
          <button onClick={onClose} className="mt-4 px-4 py-2 bg-red-600 rounded">Close</button>
        </div>
      </motion.div>
    );
  }

  return (
    <motion.div
      initial={{ opacity: 0, scale: 0.9 }}
      animate={{ opacity: 1, scale: 1 }}
      exit={{ opacity: 0, scale: 0.9 }}
      transition={{ duration: 0.3, ease: "easeOut" }}
      className="fixed inset-0 bg-black z-[70] flex items-center justify-center p-6"
      onClick={onClose}
    >
      <motion.div 
        initial={{ y: 50, opacity: 0 }}
        animate={{ y: 0, opacity: 1 }}
        exit={{ y: 50, opacity: 0 }}
        transition={{ duration: 0.4, ease: "easeOut" }}
        className="w-full h-full relative max-w-6xl mx-auto" 
        onClick={(e) => e.stopPropagation()}
      >
        {/* Enhanced Header with proper spacing */}
        <motion.div 
          initial={{ y: -20, opacity: 0 }}
          animate={{ y: 0, opacity: 1 }}
          transition={{ delay: 0.2, duration: 0.3 }}
          className="absolute top-0 left-0 right-0 z-30 bg-gradient-to-b from-black/80 to-transparent p-6"
        >
          <div className="flex items-center justify-between">
            <h3 className="text-white font-semibold text-xl truncate mr-4">{title}</h3>
            <motion.button
              whileHover={{ scale: 1.1 }}
              whileTap={{ scale: 0.9 }}
              onClick={onClose}
              className="w-12 h-12 bg-white/20 rounded-full flex items-center justify-center hover:bg-white/30 transition-colors backdrop-blur-sm"
            >
              <X className="w-6 h-6 text-white" />
            </motion.button>
          </div>
        </motion.div>

        {/* Enhanced Video Player Container with equal gaps */}
        <div 
          ref={playerRef}
          className="w-full h-full flex items-center justify-center"
          style={{
            padding: '80px 40px 40px 40px', // Top, Right, Bottom, Left - equal gaps except top for header
            fontFamily: 'Arial, sans-serif',
            backgroundColor: '#121212',
            color: 'white'
          }}
        >
          <section className="w-full h-full">
            <div className="w-full h-full">
              <div className="relative overflow-hidden rounded-lg w-full h-full" style={{ maxHeight: 'calc(100vh - 160px)' }}>
                <div className="relative w-full h-full">
                  <div className="plyr__video-embed w-full h-full" id="plyr-player">
                    {/* Enhanced Title blocker */}
                    <div 
                      className="title-blocker absolute top-0 left-0 z-20 pointer-events-auto cursor-default bg-transparent"
                      style={{ width: '30%', height: '15%' }}
                    ></div>
                    
                    {/* Enhanced Share button blocker */}
                    <div 
                      className="share-blocker absolute top-0 right-0 z-20 pointer-events-auto cursor-default bg-transparent"
                      style={{ width: '15%', height: '15%' }}
                    ></div>
                    
                    {/* Enhanced Center click layer */}
                    <div 
                      className="center-click-layer absolute top-0 left-0 w-full h-full z-10 cursor-pointer bg-transparent"
                    ></div>
                    
                    <iframe
                      src={`https://www.youtube.com/embed/${videoId}?enablejsapi=1&controls=0&disablekb=1&rel=0&showinfo=0&iv_load_policy=3&modestbranding=1&origin=${window.location.origin}&autoplay=0`}
                      className="absolute top-0 left-0 w-full h-full border-0"
                      allowFullScreen
                      allow="autoplay; encrypted-media; picture-in-picture"
                      referrerPolicy="strict-origin-when-cross-origin"
                    />
                  </div>
                </div>
              </div>
            </div>
          </section>
        </div>

        {/* Enhanced Loading indicator */}
        {isLoading && (
          <motion.div 
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="absolute inset-0 flex items-center justify-center bg-black/50 backdrop-blur-sm z-40"
          >
            <div className="text-center">
              <div className="w-16 h-16 border-4 border-white/20 border-t-white rounded-full animate-spin mb-4" />
              <p className="text-white text-sm">Loading video...</p>
            </div>
          </motion.div>
        )}
      </motion.div>

      <style jsx>{`
        /* Enhanced Player CSS */
        .plyr__controls {
          z-index: 15 !important;
          pointer-events: all !important;
          opacity: 1 !important;
          visibility: visible !important;
        }

        .plyr--video .plyr__controls {
          opacity: 1 !important;
          visibility: visible !important;
          transform: translateY(0) !important;
        }

        .plyr--playing .plyr__controls {
          transform: translateY(0) !important;
          opacity: 1 !important;
        }

        .plyr__control-bar {
          opacity: 1 !important;
          visibility: visible !important;
        }

        /* Responsive adjustments */
        @media (max-width: 768px) {
          .title-blocker {
            width: 60% !important;
            height: 12% !important;
          }
          .share-blocker {
            width: 12% !important;
            height: 12% !important;
          }
        }

        /* Prevent control hiding */
        .plyr__controls:not(.plyr__controls--hidden) {
          opacity: 1 !important;
          visibility: visible !important;
        }

        /* Enhanced click layers */
        .center-click-layer {
          background: transparent !important;
        }

        .title-blocker,
        .share-blocker {
          background: transparent !important;
        }

        /* Ensure video container takes full space */
        .plyr__video-embed iframe {
          width: 100% !important;
          height: 100% !important;
        }

        /* Ensure proper aspect ratio maintenance */
        .plyr__video-embed {
          width: 100% !important;
          height: 100% !important;
        }
      `}</style>
    </motion.div>
  );
};

// Extend Window interface for Plyr
declare global {
  interface Window {
    Plyr: any;
  }
}