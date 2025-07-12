import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import { 
  faHome, faFileText, faRss, faBell, faUser, faPlay, faSignOutAlt,
  faChevronDown, faBookOpen, faPlus, faEdit, faTrash, faArrowLeft
} from '@fortawesome/free-solid-svg-icons';
import { useData } from '../../hooks/useData';
import { useAuth } from '../../hooks/useAuth';
import { Button } from '../ui/Button';
import { PlyrPlayer } from './PlyrPlayer';
import { extractVideoId, extractVideoDurationFromEmbed, getYouTubeThumbnail } from '../../utils/youtube';
import { supabase } from '../../lib/supabase';
import toast from 'react-hot-toast';

interface FeedPageProps {
  onNavigate: (tab: string) => void;
  activeTab: string;
  onPlayerModalToggle?: (isOpen: boolean) => void;
}

interface Subject {
  id: string;
  name: string;
  description: string;
  icon: string;
  color: string;
  imageUrl?: string;
  lessonCount: number;
  lessons: Lesson[];
}

interface Lesson {
  id: string;
  title: string;
  description: string;
  subjectId: string;
  thumbnailUrl?: string;
  videoCount: number;
  videos: LessonVideo[];
}

interface LessonVideo {
  id: string;
  title: string;
  description: string;
  youtube_url: string;
  thumbnail_url: string;
  duration: string;
  lessonId: string;
  created_at: string;
}

// Enhanced Custom Loading Component
const CustomLoader: React.FC = () => (
  <div className="min-h-screen bg-white flex items-center justify-center">
    <div className="text-center">
      <div className="loader mb-4"></div>
      <p className="text-gray-600">Loading Lessons...</p>
      <style jsx>{`
        .loader {
          width: fit-content;
          font-size: 40px;
          font-family: monospace;
          font-weight: bold;
          text-transform: uppercase;
          color: #0000;
          -webkit-text-stroke: 1px #000;
          --g: conic-gradient(#000 0 0) no-repeat text;
          background: var(--g) 0, var(--g) 1ch, var(--g) 2ch, var(--g) 3ch, var(--g) 4ch, var(--g) 5ch, var(--g) 6ch;
          animation: l17-0 1s linear infinite alternate, l17-1 2s linear infinite;
        }
        .loader:before {
          content: "Loading";
        }
        @keyframes l17-0 {
          0% { background-size: 1ch 0; }
          100% { background-size: 1ch 100%; }
        }
        @keyframes l17-1 {
          0%, 50% { background-position-y: 100%, 0; }
          50.01%, to { background-position-y: 0, 100%; }
        }
      `}</style>
    </div>
  </div>
);

// Enhanced Ripple Effect Hook
const useRipple = () => {
  const [ripples, setRipples] = useState<Array<{ x: number; y: number; id: number }>>([]);

  const createRipple = (event: React.MouseEvent<HTMLElement>) => {
    const rect = event.currentTarget.getBoundingClientRect();
    const x = event.clientX - rect.left;
    const y = event.clientY - rect.top;
    const id = Date.now() + Math.random();

    setRipples(prev => [...prev, { x, y, id }]);

    setTimeout(() => {
      setRipples(prev => prev.filter(ripple => ripple.id !== id));
    }, 1500);
  };

  return { ripples, createRipple };
};

// Enhanced Ripple Component
const RippleEffect: React.FC<{ ripples: Array<{ x: number; y: number; id: number }> }> = ({ ripples }) => (
  <>
    {ripples.map(ripple => (
      <motion.div
        key={ripple.id}
        className="absolute bg-black/15 rounded-full pointer-events-none z-20"
        style={{
          left: ripple.x - 100,
          top: ripple.y - 100,
          width: 200,
          height: 200,
        }}
        initial={{ scale: 0, opacity: 0.8 }}
        animate={{ scale: 4, opacity: 0 }}
        transition={{ duration: 1.5, ease: [0.4, 0, 0.2, 1] }}
      />
    ))}
  </>
);

// Loading Line Component
const LoadingLine: React.FC<{ isLoading: boolean }> = ({ isLoading }) => (
  <AnimatePresence>
    {isLoading && (
      <motion.div
        initial={{ width: 0 }}
        animate={{ width: '100%' }}
        exit={{ width: 0 }}
        transition={{ duration: 1.5, ease: "easeInOut" }}
        className="absolute bottom-0 left-0 h-1 bg-gradient-to-r from-blue-500 to-purple-600 z-30"
      />
    )}
  </AnimatePresence>
);

export const FeedPage: React.FC<FeedPageProps> = ({ onNavigate, activeTab, onPlayerModalToggle }) => {
  const { lessons } = useData();
  const { user, signOut } = useAuth();
  const [showVideoPlayer, setShowVideoPlayer] = useState(false);
  const [selectedVideo, setSelectedVideo] = useState<any>(null);
  const [selectedSubject, setSelectedSubject] = useState<Subject | null>(null);
  const [selectedLesson, setSelectedLesson] = useState<Lesson | null>(null);
  const [currentView, setCurrentView] = useState<'subjects' | 'lessons' | 'videos'>('subjects');
  const [subjects, setSubjects] = useState<Subject[]>([]);
  const [loading, setLoading] = useState(true);
  const [loadingContainers, setLoadingContainers] = useState<Set<string>>(new Set());

  // Load subjects from database
  useEffect(() => {
    loadSubjects();
  }, []);

  const loadSubjects = async () => {
    try {
      setLoading(true);
      
      // Load subjects from database
      const { data: subjectsData, error: subjectsError } = await supabase
        .from('subjects')
        .select('*')
        .order('created_at', { ascending: true });

      if (subjectsError) {
        console.log('Subjects table does not exist, using default subjects');
        setSubjects(getDefaultSubjects());
        setLoading(false);
        return;
      }

      // Load lessons for each subject
      const { data: lessonsData, error: lessonsError } = await supabase
        .from('subject_lessons')
        .select('*')
        .order('created_at', { ascending: true });

      if (lessonsError) {
        console.error('Error loading lessons:', lessonsError);
      }

      // Load videos for each lesson
      const { data: videosData, error: videosError } = await supabase
        .from('lesson_videos')
        .select('*')
        .order('created_at', { ascending: true });

      if (videosError) {
        console.error('Error loading videos:', videosError);
      }

      // Organize data into hierarchical structure
      const organizedSubjects = (subjectsData || getDefaultSubjects()).map(subject => {
        const subjectLessons = (lessonsData || [])
          .filter(lesson => lesson.subject_id === subject.id)
          .map(lesson => {
            const lessonVideos = (videosData || [])
              .filter(video => video.lesson_id === lesson.id)
              .map(video => ({
                id: video.id,
                title: video.title,
                description: video.description,
                youtube_url: video.youtube_url,
                thumbnail_url: video.thumbnail_url,
                duration: video.duration,
                lessonId: lesson.id,
                subjectId: subject.id,
                created_at: video.created_at
              }));

            return {
              id: lesson.id,
              title: lesson.title,
              description: lesson.description,
              subjectId: subject.id,
              thumbnailUrl: lesson.thumbnail_url,
              videoCount: lessonVideos.length,
              videos: lessonVideos
            };
          });

        return {
          id: subject.id,
          name: subject.name,
          description: subject.description,
          icon: subject.icon,
          color: subject.color,
          imageUrl: subject.image_url,
          lessonCount: subjectLessons.length,
          lessons: subjectLessons
        };
      });

      setSubjects(organizedSubjects);
    } catch (error) {
      console.error('Error loading data:', error);
      setSubjects(getDefaultSubjects());
    } finally {
      setLoading(false);
    }
  };

  const getDefaultSubjects = (): Subject[] => [
    {
      id: 'sft',
      name: 'SFT',
      description: 'Science for Technology - Core scientific principles',
      icon: '🔬',
      color: 'from-green-500 to-emerald-600',
      imageUrl: 'https://images.pexels.com/photos/2280571/pexels-photo-2280571.jpeg',
      lessonCount: 0,
      lessons: []
    },
    {
      id: 'et',
      name: 'ET',
      description: 'Engineering Technology - Applied engineering concepts',
      icon: '⚙️',
      color: 'from-orange-500 to-amber-600',
      imageUrl: 'https://images.pexels.com/photos/159298/gears-cogs-machine-machinery-159298.jpeg',
      lessonCount: 0,
      lessons: []
    },
    {
      id: 'ict',
      name: 'ICT',
      description: 'Information & Communication Technology',
      icon: '💻',
      color: 'from-blue-500 to-indigo-600',
      imageUrl: 'https://images.pexels.com/photos/546819/pexels-photo-546819.jpeg',
      lessonCount: 0,
      lessons: []
    }
  ];

  const openVideo = (video: LessonVideo) => {
    setSelectedVideo(video);
    setShowVideoPlayer(true);
    onPlayerModalToggle?.(true);
  };

  const closeVideoPlayer = () => {
    setShowVideoPlayer(false);
    setSelectedVideo(null);
    onPlayerModalToggle?.(false);
  };

  const handleContainerClick = (id: string, action: () => void) => {
    setLoadingContainers(prev => new Set(prev).add(id));
    
    setTimeout(() => {
      setLoadingContainers(prev => {
        const newSet = new Set(prev);
        newSet.delete(id);
        return newSet;
      });
      action();
    }, 1500);
  };

  const handleSubjectClick = (subject: Subject) => {
    setSelectedSubject(subject);
    setCurrentView('lessons');
  };

  const handleLessonClick = (lesson: Lesson) => {
    setSelectedLesson(lesson);
    setCurrentView('videos');
  };

  const handleBackToSubjects = () => {
    setSelectedSubject(null);
    setSelectedLesson(null);
    setCurrentView('subjects');
  };

  const handleBackToLessons = () => {
    setSelectedLesson(null);
    setCurrentView('lessons');
  };

  if (loading) {
    return <CustomLoader />;
  }

  const bottomNavItems = [
    { id: 'home', name: 'Home', icon: faHome }, 
    { id: 'recent', name: 'Recent', icon: faFileText },
    { id: 'lessons', name: 'Lessons', icon: faRss }, 
    { id: 'notifications', name: 'Notifications', icon: faBell },
    { id: 'profile', name: 'Profile', icon: faUser },
  ];

  return (
    <div className="min-h-screen bg-white">
      <div className="w-full px-4 py-6 pb-24">
        {/* Enhanced Header */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.4, ease: "easeOut" }}
          className="flex items-center justify-between mb-6"
        >
          <div className="flex items-center space-x-3">
            {currentView !== 'subjects' && (
              <motion.button
                whileHover={{ scale: 1.1 }}
                whileTap={{ scale: 0.9 }}
                onClick={currentView === 'videos' ? handleBackToLessons : handleBackToSubjects}
                className="p-2 hover:bg-gray-100 rounded-lg transition-colors"
              >
                <FontAwesomeIcon icon={faArrowLeft} className="w-5 h-5 text-gray-600" />
              </motion.button>
            )}
            <div>
              {currentView === 'subjects' && (
                <h2 className="text-xl font-bold text-gray-900">Learning Subjects</h2>
              )}
              {currentView === 'lessons' && selectedSubject && (
                <div>
                  <h2 className="text-xl font-bold text-gray-900">{selectedSubject.name} Lessons</h2>
                  <p className="text-sm text-gray-600">{selectedSubject.lessons.length} lessons available</p>
                </div>
              )}
              {currentView === 'videos' && selectedLesson && (
                <div>
                  <h2 className="text-xl font-bold text-gray-900">{selectedLesson.title}</h2>
                  <p className="text-sm text-gray-600">{selectedLesson.videos.length} videos available</p>
                </div>
              )}
            </div>
          </div>
          <Button 
            variant="outline" 
            size="sm"
            onClick={signOut}
            className="border-gray-300 text-gray-700 hover:bg-gray-50 text-sm px-4 py-2"
          >
            <FontAwesomeIcon icon={faSignOutAlt} className="w-4 h-4 mr-2" />
            Sign Out
          </Button>
        </motion.div>

        {/* Content based on current view */}
        <AnimatePresence mode="wait">
          {currentView === 'subjects' && (
            <SubjectsView 
              subjects={subjects} 
              onSubjectClick={handleSubjectClick}
              loadingContainers={loadingContainers}
              onContainerClick={handleContainerClick}
            />
          )}

          {currentView === 'lessons' && selectedSubject && (
            <LessonsView 
              subject={selectedSubject} 
              onLessonClick={handleLessonClick}
              loadingContainers={loadingContainers}
              onContainerClick={handleContainerClick}
            />
          )}

          {currentView === 'videos' && selectedLesson && (
            <VideosView 
              lesson={selectedLesson} 
              onVideoClick={openVideo}
              loadingContainers={loadingContainers}
              onContainerClick={handleContainerClick}
            />
          )}
        </AnimatePresence>
      </div>

      {/* Enhanced Plyr Video Player Modal */}
      <AnimatePresence>
        {showVideoPlayer && selectedVideo && (
          <PlyrPlayer
            videoUrl={selectedVideo.youtube_url}
            title={selectedVideo.title}
            onClose={closeVideoPlayer}
          />
        )}
      </AnimatePresence>

      {/* Enhanced Bottom Navigation */}
      <div className="fixed bottom-0 left-0 right-0 bg-white/90 backdrop-blur-md border-t border-gray-200/50 z-50">
        <div className="w-full px-4">
          <nav className="flex justify-around py-2">
            {bottomNavItems.map((item) => (
              <motion.button
                key={item.id}
                whileTap={{ scale: 0.95 }}
                onClick={() => onNavigate(item.id)}
                className={`relative flex flex-col items-center py-2 px-3 rounded-xl transition-all duration-200 ${
                  activeTab === item.id
                    ? 'text-blue-600 bg-blue-50 shadow-lg scale-105' 
                    : 'text-gray-500 hover:text-gray-700 hover:bg-gray-50'
                }`}
              >
                <FontAwesomeIcon icon={item.icon} className="w-5 h-5 mb-1" />
                <span className="text-xs font-medium">{item.name}</span>
                {activeTab === item.id && (
                  <motion.div
                    layoutId="activeTab"
                    className="absolute inset-0 bg-blue-100 rounded-xl -z-10"
                    transition={{ type: "spring", stiffness: 500, damping: 30 }}
                  />
                )}
              </motion.button>
            ))}
          </nav>
        </div>
      </div>
    </div>
  );
};

// Enhanced Subjects View Component
const SubjectsView: React.FC<{ 
  subjects: Subject[]; 
  onSubjectClick: (subject: Subject) => void;
  loadingContainers: Set<string>;
  onContainerClick: (id: string, action: () => void) => void;
}> = ({ subjects, onSubjectClick, loadingContainers, onContainerClick }) => {
  const { ripples, createRipple } = useRipple();

  return (
    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
      {subjects.map((subject, index) => (
        <motion.div
          key={subject.id}
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: index * 0.1 }}
          className="group relative bg-white rounded-2xl shadow-lg border border-gray-100 overflow-hidden hover:shadow-xl transition-all duration-300 cursor-pointer"
          onClick={(e) => {
            createRipple(e);
            onContainerClick(subject.id, () => onSubjectClick(subject));
          }}
        >
          <RippleEffect ripples={ripples} />
          <LoadingLine isLoading={loadingContainers.has(subject.id)} />
          
          {/* Subject Image with 16:9 aspect ratio */}
          <div className="relative w-full" style={{ aspectRatio: '16/9' }}>
            <img 
              src={subject.imageUrl} 
              alt={subject.name} 
              className="w-full h-full object-cover"
              loading="lazy"
              onError={(e) => { 
                e.currentTarget.src = 'https://via.placeholder.com/320x180?text=Subject'; 
              }} 
            />
            
            {/* Enhanced Lesson Count Badge */}
            <div className="absolute bottom-3 right-3 bg-black/80 text-white text-xs px-3 py-1.5 rounded-lg backdrop-blur-sm font-medium">
              {subject.lessonCount} Lessons
            </div>
          </div>

          {/* Enhanced Content */}
          <div className="p-5">
            <div className="flex items-start justify-between mb-3">
              <h3 className="font-bold text-gray-900 text-lg line-clamp-1 leading-tight">
                {subject.name}
              </h3>
            </div>

            <p className="text-gray-600 mb-4 leading-relaxed text-sm line-clamp-2">
              {subject.description}
            </p>

            {/* Enhanced Meta Information */}
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2 text-xs text-gray-500">
                <span className={`px-3 py-1 bg-gradient-to-r ${subject.color} text-white rounded-full font-semibold text-xs`}>
                  {subject.name}
                </span>
                <span>{subject.lessonCount} Lessons</span>
              </div>
            </div>
          </div>
        </motion.div>
      ))}
    </div>
  );
};

// Enhanced Lessons View Component
const LessonsView: React.FC<{ 
  subject: Subject; 
  onLessonClick: (lesson: Lesson) => void;
  loadingContainers: Set<string>;
  onContainerClick: (id: string, action: () => void) => void;
}> = ({ subject, onLessonClick, loadingContainers, onContainerClick }) => {
  const { ripples, createRipple } = useRipple();

  return (
    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
      {subject.lessons.map((lesson, index) => (
        <motion.div
          key={lesson.id}
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: index * 0.1 }}
          className="group relative bg-white rounded-2xl shadow-lg border border-gray-100 overflow-hidden hover:shadow-xl transition-all duration-300 cursor-pointer"
          onClick={(e) => {
            createRipple(e);
            onContainerClick(lesson.id, () => onLessonClick(lesson));
          }}
        >
          <RippleEffect ripples={ripples} />
          <LoadingLine isLoading={loadingContainers.has(lesson.id)} />
          
          {/* Lesson Image with 16:9 aspect ratio */}
          <div className="relative w-full" style={{ aspectRatio: '16/9' }}>
            <img 
              src={lesson.thumbnailUrl || 'https://via.placeholder.com/320x180?text=Lesson'} 
              alt={lesson.title} 
              className="w-full h-full object-cover"
              loading="lazy"
              onError={(e) => { 
                e.currentTarget.src = 'https://via.placeholder.com/320x180?text=Lesson'; 
              }} 
            />
            
            {/* Enhanced Video Count Badge */}
            <div className="absolute bottom-3 right-3 bg-black/80 text-white text-xs px-3 py-1.5 rounded-lg backdrop-blur-sm font-medium">
              {lesson.videoCount} Videos
            </div>
          </div>

          {/* Enhanced Content */}
          <div className="p-5">
            <div className="flex items-start justify-between mb-3">
              <h3 className="font-bold text-gray-900 text-lg line-clamp-1 leading-tight">
                {lesson.title}
              </h3>
            </div>

            <p className="text-gray-600 mb-4 leading-relaxed text-sm line-clamp-2">
              {lesson.description}
            </p>

            {/* Enhanced Meta Information */}
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2 text-xs text-gray-500">
                <FontAwesomeIcon icon={faPlay} className="w-3 h-3" />
                <span>{lesson.videoCount} Videos</span>
              </div>
            </div>
          </div>
        </motion.div>
      ))}

      {subject.lessons.length === 0 && (
        <div className="text-center py-12 col-span-full">
          <div className="w-16 h-16 bg-gray-100 rounded-full flex items-center justify-center mx-auto mb-4">
            <FontAwesomeIcon icon={faBookOpen} className="w-8 h-8 text-gray-400" />
          </div>
          <h3 className="text-lg font-medium text-gray-900 mb-2">No Lessons Yet</h3>
          <p className="text-gray-600 text-sm mb-4">Start by adding your first lesson to this subject.</p>
        </div>
      )}
    </div>
  );
};

// Enhanced Videos View Component
const VideosView: React.FC<{ 
  lesson: Lesson; 
  onVideoClick: (video: LessonVideo) => void;
  loadingContainers: Set<string>;
  onContainerClick: (id: string, action: () => void) => void;
}> = ({ lesson, onVideoClick, loadingContainers, onContainerClick }) => {
  const { ripples, createRipple } = useRipple();

  return (
    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
      {lesson.videos.map((video, index) => (
        <motion.div
          key={video.id}
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: index * 0.1 }}
          className="group relative bg-white rounded-2xl shadow-lg border border-gray-100 overflow-hidden hover:shadow-xl transition-all duration-300 cursor-pointer"
          onClick={(e) => {
            createRipple(e);
            onContainerClick(video.id, () => onVideoClick(video));
          }}
        >
          <RippleEffect ripples={ripples} />
          <LoadingLine isLoading={loadingContainers.has(video.id)} />
          
          {/* Video Thumbnail with 16:9 aspect ratio */}
          <div className="relative w-full" style={{ aspectRatio: '16/9' }}>
            <img 
              src={video.thumbnail_url || getYouTubeThumbnail(video.youtube_url)} 
              alt={video.title} 
              className="w-full h-full object-cover"
              loading="lazy"
              onError={(e) => { 
                e.currentTarget.src = 'https://via.placeholder.com/320x180?text=Video'; 
              }} 
            />
            
            {/* Enhanced Play Button */}
            <div className="absolute inset-0 flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity duration-300">
              <div className="w-16 h-16 bg-white/90 rounded-full flex items-center justify-center shadow-lg backdrop-blur-sm">
                <FontAwesomeIcon icon={faPlay} className="w-6 h-6 text-gray-800 ml-1" />
              </div>
            </div>
            
            {/* Enhanced Duration Badge */}
            <div className="absolute bottom-3 right-3 bg-black/80 text-white text-xs px-3 py-1.5 rounded-lg backdrop-blur-sm font-medium">
              {video.duration}
            </div>
          </div>

          {/* Enhanced Content */}
          <div className="p-5">
            <div className="flex items-start justify-between mb-3">
              <h3 className="font-bold text-gray-900 text-lg line-clamp-1 leading-tight">
                {video.title}
              </h3>
            </div>

            <p className="text-gray-600 mb-4 leading-relaxed text-sm line-clamp-2">
              {video.description}
            </p>

            {/* Enhanced Meta Information */}
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2 text-xs text-gray-500">
                <FontAwesomeIcon icon={faPlay} className="w-3 h-3" />
                <span>{video.duration}</span>
              </div>
              
              <div className="text-xs text-gray-400 font-medium">
                {new Date(video.created_at).toLocaleDateString()}
              </div>
            </div>
          </div>
        </motion.div>
      ))}

      {lesson.videos.length === 0 && (
        <div className="text-center py-12 col-span-full">
          <div className="w-16 h-16 bg-gray-100 rounded-full flex items-center justify-center mx-auto mb-4">
            <FontAwesomeIcon icon={faPlay} className="w-8 h-8 text-gray-400" />
          </div>
          <h3 className="text-lg font-medium text-gray-900 mb-2">No Videos Yet</h3>
          <p className="text-gray-600 text-sm mb-4">Start by adding your first video to this lesson.</p>
        </div>
      )}
    </div>
  );
};