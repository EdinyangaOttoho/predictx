import React, { useState } from 'react';
import Header from './components/Header';
import EventCard from './components/EventCard';
import StatsCard from './components/StatsCard';
import { TrendingUp, Gamepad2, Users as UsersIcon, Sparkles } from 'lucide-react';

const events = [
  {
    title: "League of Legends Worlds Finals",
    category: "Gaming",
    endTime: "24h remaining",
    participants: 1420,
    prizePool: "50 ETH",
    odds: "1.5x",
    imageUrl: "https://images.unsplash.com/photo-1542751371-adc38448a05e?auto=format&fit=crop&q=80&w=2070",
    featured: true
  },
  {
    title: "Oscars Best Picture",
    category: "Social",
    endTime: "5d remaining",
    participants: 890,
    prizePool: "25 ETH",
    odds: "2.1x",
    imageUrl: "https://images.unsplash.com/photo-1485095329183-d0797cdc5676?auto=format&fit=crop&q=80&w=2070"
  },
  {
    title: "CS:GO Major Finals",
    category: "Gaming",
    endTime: "2d remaining",
    participants: 2150,
    prizePool: "75 ETH",
    odds: "1.8x",
    imageUrl: "https://images.unsplash.com/photo-1542751110-97427bbecf20?auto=format&fit=crop&q=80&w=2070",
    featured: true
  },
  {
    title: "Valorant Champions Tour",
    category: "Gaming",
    endTime: "3d remaining",
    participants: 1850,
    prizePool: "60 ETH",
    odds: "1.6x",
    imageUrl: "https://images.unsplash.com/photo-1538481199705-c710c4e965fc?auto=format&fit=crop&q=80&w=2070"
  },
  {
    title: "Grammy Awards 2024",
    category: "Social",
    endTime: "7d remaining",
    participants: 3200,
    prizePool: "100 ETH",
    odds: "2.3x",
    imageUrl: "https://images.unsplash.com/photo-1514525253161-7a46d19cd819?auto=format&fit=crop&q=80&w=2070",
    featured: true
  },
  {
    title: "Super Bowl LVIII",
    category: "Sports",
    endTime: "15d remaining",
    participants: 5600,
    prizePool: "200 ETH",
    odds: "1.9x",
    imageUrl: "https://images.unsplash.com/photo-1495727034151-8fdc73e332a8?auto=format&fit=crop&q=80&w=2070"
  }
];

function App() {
  const [activeCategory, setActiveCategory] = useState('All');
  const categories = ['All', 'Gaming', 'Social', 'Sports'];

  const filteredEvents = activeCategory === 'All' 
    ? events 
    : events.filter(event => event.category === activeCategory);

  return (
    <div className="min-h-screen bg-midnight-950">
      <Header />
      
      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Featured Event Banner */}
        <div className="relative rounded-2xl overflow-hidden mb-12 bg-gradient-to-r from-midnight-800 to-midnight-900 shadow-2xl">
          <div className="absolute inset-0 bg-gradient-to-r from-neon-400/20 to-transparent"></div>
          <div className="relative p-8 md:p-12">
            <div className="flex items-center gap-2 mb-4">
              <Sparkles className="w-5 h-5 text-neon-400" />
              <span className="text-neon-400 font-medium">Featured Event</span>
            </div>
            <h2 className="text-3xl md:text-4xl font-bold text-white mb-4">Grammy Awards 2024</h2>
            <p className="text-gray-300 mb-6 max-w-2xl">Place your predictions on the most prestigious music awards ceremony. Over 5,600 participants and growing!</p>
            <button className="bg-neon-500 text-white px-8 py-3 rounded-lg hover:bg-neon-600 transition-all transform hover:scale-105">
              Predict Now
            </button>
          </div>
        </div>

        {/* Stats Section */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-12">
          <StatsCard 
            icon={<TrendingUp className="w-6 h-6 text-neon-400" />}
            label="Total Volume"
            value="1,234 ETH"
          />
          <StatsCard 
            icon={<Gamepad2 className="w-6 h-6 text-neon-400" />}
            label="Active Events"
            value="24"
          />
          <StatsCard 
            icon={<UsersIcon className="w-6 h-6 text-neon-400" />}
            label="Total Users"
            value="5.2K"
          />
        </div>

        {/* Category Filters */}
        <div className="flex gap-4 mb-8 overflow-x-auto pb-2">
          {categories.map((category) => (
            <button
              key={category}
              onClick={() => setActiveCategory(category)}
              className={`px-6 py-2 rounded-lg transition-all ${
                activeCategory === category
                  ? 'bg-neon-500 text-white'
                  : 'bg-midnight-800 text-gray-300 hover:bg-midnight-700'
              }`}
            >
              {category}
            </button>
          ))}
        </div>

        {/* Events Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {filteredEvents.map((event, index) => (
            <EventCard key={index} {...event} />
          ))}
        </div>
      </main>
    </div>
  );
}

export default App;