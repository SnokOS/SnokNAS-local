import React, { useState } from 'react';
import { LayoutDashboard, Server, HardDrive, Network, Settings, LogOut, Cpu, Activity, Disc } from 'lucide-react';
import RackStation from './components/RackStation';
import SystemInfo from './components/SystemInfo';

function App() {
    const [activeTab, setActiveTab] = useState('dashboard');

    const menuItems = [
        { id: 'dashboard', icon: LayoutDashboard, label: 'Dashboard' },
        { id: 'storage', icon: HardDrive, label: 'Storage & Pools' },
        { id: 'network', icon: Network, label: 'Network' },
        { id: 'virtualization', icon: Server, label: 'Virtualization' },
        { id: 'settings', icon: Settings, label: 'System Settings' },
    ];

    return (
        <div className="min-h-screen flex bg-snok-bg text-snok-text font-sans overflow-hidden">
            {/* Sidebar */}
            <aside className="w-64 glass-panel border-r border-white/10 flex flex-col z-20">
                <div className="p-6 flex items-center gap-3">
                    <div className="w-10 h-10 rounded-lg bg-gradient-to-br from-snok-primary to-snok-accent flex items-center justify-center neon-border">
                        <Server className="w-6 h-6 text-white" />
                    </div>
                    <div>
                        <h1 className="text-xl font-bold tracking-tight text-transparent bg-clip-text bg-gradient-to-r from-white to-snok-muted">SnokNAS</h1>
                        <span className="text-xs text-snok-muted uppercase tracking-wider">Enterprise</span>
                    </div>
                </div>

                <nav className="flex-1 px-4 py-4 space-y-2">
                    {menuItems.map((item) => (
                        <button
                            key={item.id}
                            onClick={() => setActiveTab(item.id)}
                            className={`w-full flex items-center gap-3 px-4 py-3 rounded-xl transition-all duration-300 group ${activeTab === item.id
                                    ? 'bg-snok-primary/20 text-snok-primary border border-snok-primary/20 shadow-[0_0_15px_rgba(59,130,246,0.1)]'
                                    : 'text-snok-muted hover:bg-white/5 hover:text-white'
                                }`}
                        >
                            <item.icon className={`w-5 h-5 ${activeTab === item.id ? 'animate-pulse-slow' : 'group-hover:scale-110 transition-transform'}`} />
                            <span className="font-medium">{item.label}</span>
                        </button>
                    ))}
                </nav>

                <div className="p-4 border-t border-white/10">
                    <button className="w-full flex items-center gap-3 px-4 py-3 rounded-xl text-snok-error hover:bg-snok-error/10 transition-colors">
                        <LogOut className="w-5 h-5" />
                        <span className="font-medium">Logout</span>
                    </button>
                </div>
            </aside>

            {/* Main Content */}
            <main className="flex-1 overflow-y-auto relative">
                {/* Background Gradients */}
                <div className="absolute top-0 left-0 w-full h-96 bg-gradient-to-b from-snok-primary/5 to-transparent pointer-events-none" />

                <header className="sticky top-0 z-10 glass-panel border-b border-white/5 px-8 py-4 flex justify-between items-center">
                    <h2 className="text-2xl font-semibold">{menuItems.find(i => i.id === activeTab)?.label}</h2>
                    <div className="flex items-center gap-4">
                        <div className="flex items-center gap-2 px-3 py-1.5 rounded-full bg-snok-success/20 border border-snok-success/30 text-snok-success text-sm font-medium animate-pulse">
                            <Activity className="w-4 h-4" />
                            <span>System Healthy</span>
                        </div>
                        <div className="w-10 h-10 rounded-full bg-snok-surface border border-white/10 flex items-center justify-center">
                            <span className="font-bold text-snok-primary">A</span>
                        </div>
                    </div>
                </header>

                <div className="p-8 space-y-8 max-w-7xl mx-auto">
                    {/* Dashboard View */}
                    {activeTab === 'dashboard' && (
                        <>
                            {/* System Info Cards */}
                            <SystemInfo />

                            <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
                                {/* Rack Visualization - Takes up 2 columns */}
                                <div className="lg:col-span-2">
                                    <RackStation />
                                </div>

                                {/* Quick Actions / Notifications */}
                                <div className="glass-panel rounded-2xl p-6 h-full">
                                    <h3 className="text-lg font-semibold mb-4 flex items-center gap-2">
                                        <Disc className="w-5 h-5 text-snok-accent" />
                                        Storage Pools
                                    </h3>
                                    <div className="space-y-4">
                                        <div className="glass-card p-4 rounded-xl space-y-2">
                                            <div className="flex justify-between items-center">
                                                <span className="font-medium">Data_Pool_01</span>
                                                <span className="text-sm text-snok-success">Online</span>
                                            </div>
                                            <div className="w-full bg-snok-bg rounded-full h-2 overflow-hidden">
                                                <div className="bg-snok-primary h-full w-[45%]" />
                                            </div>
                                            <div className="flex justify-between text-xs text-snok-muted">
                                                <span>14.5 TB Used</span>
                                                <span>32 TB Total</span>
                                            </div>
                                        </div>
                                        <div className="glass-card p-4 rounded-xl space-y-2">
                                            <div className="flex justify-between items-center">
                                                <span className="font-medium">Fast_Flash_01</span>
                                                <span className="text-sm text-snok-success">Online</span>
                                            </div>
                                            <div className="w-full bg-snok-bg rounded-full h-2 overflow-hidden">
                                                <div className="bg-snok-accent h-full w-[12%]" />
                                            </div>
                                            <div className="flex justify-between text-xs text-snok-muted">
                                                <span>120 GB Used</span>
                                                <span>1 TB Total</span>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </>
                    )}

                    {activeTab !== 'dashboard' && (
                        <div className="flex flex-col items-center justify-center h-96 text-snok-muted">
                            <Cpu className="w-16 h-16 mb-4 opacity-20" />
                            <p className="text-xl">Module under development...</p>
                        </div>
                    )}
                </div>
            </main>
        </div>
    )
}

export default App
