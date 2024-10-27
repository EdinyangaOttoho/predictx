import React from 'react';
import { Sword, Bell, Wallet } from 'lucide-react';

export default function Header() {
  return (
    <header className="bg-midnight-900 border-b border-midnight-800">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex justify-between items-center h-16">
          <div className="flex items-center gap-2">
            <Sword className="w-8 h-8 text-neon-500" />
            <span className="text-xl font-bold text-white">PredictX</span>
          </div>
          
          <nav className="hidden md:flex space-x-8">
            <a href="#" className="text-gray-300 hover:text-neon-400 transition-colors">Gaming</a>
            <a href="#" className="text-gray-300 hover:text-neon-400 transition-colors">Social</a>
            <a href="#" className="text-gray-300 hover:text-neon-400 transition-colors">Leaderboard</a>
            <a href="#" className="text-gray-300 hover:text-neon-400 transition-colors">My Predictions</a>
          </nav>

          <div className="flex items-center gap-4">
            <button className="p-2 text-gray-400 hover:text-neon-400 transition-colors">
              <Bell className="w-6 h-6" />
            </button>
            <button className="flex items-center gap-2 bg-neon-500 text-white px-4 py-2 rounded-lg hover:bg-neon-600 transition-all transform hover:scale-105">
              <Wallet className="w-5 h-5" />
              Connect Wallet
            </button>
          </div>
        </div>
      </div>
    </header>
  );
}