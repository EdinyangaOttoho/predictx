import React from 'react';
import { Timer, Trophy, Users, Ticket, Sparkles } from 'lucide-react';

interface EventCardProps {
  title: string;
  category: string;
  endTime: string;
  participants: number;
  prizePool: string;
  odds: string;
  imageUrl: string;
  featured?: boolean;
}

export default function EventCard({
  title,
  category,
  endTime,
  participants,
  prizePool,
  odds,
  imageUrl,
  featured
}: EventCardProps) {
  return (
    <div className="bg-midnight-800 rounded-xl overflow-hidden transition-all hover:scale-[1.02] hover:shadow-xl hover:shadow-neon-500/10">
      <div className="relative h-48">
        <img src={imageUrl} alt={title} className="w-full h-full object-cover" />
        <div className="absolute inset-0 bg-gradient-to-t from-midnight-900 to-transparent opacity-60"></div>
        <div className="absolute top-4 right-4 bg-neon-500 text-white px-3 py-1 rounded-full text-sm font-medium">
          {category}
        </div>
        {featured && (
          <div className="absolute top-4 left-4 flex items-center gap-1 bg-white/10 backdrop-blur-sm text-white px-3 py-1 rounded-full text-sm">
            <Sparkles className="w-4 h-4" />
            <span>Featured</span>
          </div>
        )}
      </div>
      <div className="p-6">
        <h3 className="text-xl font-bold text-white mb-2">{title}</h3>
        
        <div className="grid grid-cols-2 gap-4 mb-4">
          <div className="flex items-center gap-2">
            <Timer className="w-5 h-5 text-neon-400" />
            <span className="text-sm text-gray-300">{endTime}</span>
          </div>
          <div className="flex items-center gap-2">
            <Users className="w-5 h-5 text-neon-400" />
            <span className="text-sm text-gray-300">{participants} participants</span>
          </div>
        </div>

        <div className="flex justify-between items-center mb-4">
          <div className="flex items-center gap-2">
            <Trophy className="w-5 h-5 text-yellow-500" />
            <span className="text-sm font-medium text-white">{prizePool}</span>
          </div>
          <div className="text-sm font-medium text-white">
            Odds: <span className="text-neon-400">{odds}</span>
          </div>
        </div>

        <button className="w-full bg-midnight-700 text-white py-2 px-4 rounded-lg flex items-center justify-center gap-2 hover:bg-neon-500 transition-all group">
          <Ticket className="w-5 h-5 group-hover:scale-110 transition-transform" />
          Place Prediction
        </button>
      </div>
    </div>
  );
}