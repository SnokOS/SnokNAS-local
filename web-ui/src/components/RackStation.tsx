import React from 'react';
import { HardDrive, AlertCircle, CheckCircle2, Thermometer } from 'lucide-react';

const DriveBay = ({ id, status, temp, capacity, usage, type }: any) => {
    const isHealthy = status === 'healthy';
    const usagePercent = (usage / capacity) * 100;

    return (
        <div className={`relative group glass-card p-4 flex flex-col justify-between h-52 transition-all duration-300 ${!isHealthy ? 'border-snok-error/50 bg-snok-error/5' : 'border-white/5'}`}>

            {/* Drive Status LED */}
            <div className={`absolute top-3 right-3 w-3 h-3 rounded-full shadow-[0_0_10px] ${isHealthy ? 'bg-snok-success shadow-snok-success/50' : 'bg-snok-error shadow-snok-error/50 animate-pulse'}`} />

            {/* Drive Icon & Type */}
            <div className="flex items-start gap-3">
                <div className={`p-3 rounded-lg ${isHealthy ? 'bg-snok-surface' : 'bg-snok-error/10'}`}>
                    <HardDrive className={`w-8 h-8 ${isHealthy ? 'text-snok-primary' : 'text-snok-error'}`} />
                </div>
                <div>
                    <h4 className="font-bold text-lg">Bay {id}</h4>
                    <span className="text-xs text-snok-muted uppercase tracking-wider">{type}</span>
                </div>
            </div>

            {/* Stats */}
            <div className="space-y-3">
                <div className="flex justify-between items-center text-sm">
                    <span className="text-snok-muted">Status</span>
                    <span className={`flex items-center gap-1 font-medium ${isHealthy ? 'text-snok-success' : 'text-snok-error'}`}>
                        {isHealthy ? <CheckCircle2 className="w-3 h-3" /> : <AlertCircle className="w-3 h-3" />}
                        {status.toUpperCase()}
                    </span>
                </div>

                <div className="flex justify-between items-center text-sm">
                    <span className="text-snok-muted flex items-center gap-1"><Thermometer className="w-3 h-3" /> Temp</span>
                    <span className={`font-medium ${temp > 45 ? 'text-snok-warning' : 'text-snok-text'}`}>{temp}°C</span>
                </div>

                {/* Capacity Bar */}
                <div className="space-y-1">
                    <div className="flex justify-between text-xs text-snok-muted">
                        <span>{usage}TB Used</span>
                        <span>{capacity}TB</span>
                    </div>
                    <div className="w-full bg-snok-bg h-1.5 rounded-full overflow-hidden">
                        <div
                            className={`h-full rounded-full transition-all duration-1000 ${usagePercent > 90 ? 'bg-snok-warning' : 'bg-snok-primary'}`}
                            style={{ width: `${usagePercent}%` }}
                        />
                    </div>
                </div>
            </div>

            {/* Hover Detail Overlay (Visual touch) */}
            <div className="absolute inset-0 bg-snok-surface/90 opacity-0 group-hover:opacity-100 transition-opacity duration-300 flex items-center justify-center backdrop-blur-sm rounded-xl">
                <button className="px-4 py-2 bg-snok-primary text-white rounded-lg font-medium shadow-lg hover:bg-snok-primary/80 transition-colors">
                    View Details
                </button>
            </div>
        </div>
    );
};

const RackStation = () => {
    // Mock Data mimicking a real 8-bay server
    const drives = [
        { id: 1, status: 'healthy', temp: 32, capacity: 4, usage: 2.1, type: 'HDD - WD Red' },
        { id: 2, status: 'healthy', temp: 33, capacity: 4, usage: 2.4, type: 'HDD - WD Red' },
        { id: 3, status: 'healthy', temp: 31, capacity: 4, usage: 1.8, type: 'HDD - WD Red' },
        { id: 4, status: 'healthy', temp: 34, capacity: 4, usage: 2.9, type: 'HDD - WD Red' },
        { id: 5, status: 'healthy', temp: 32, capacity: 4, usage: 0.5, type: 'HDD - WD Red' },
        { id: 6, status: 'degraded', temp: 48, capacity: 4, usage: 3.1, type: 'HDD - WD Red' },
        { id: 7, status: 'healthy', temp: 28, capacity: 1, usage: 0.2, type: 'SSD - Samsung' },
        { id: 8, status: 'healthy', temp: 29, capacity: 1, usage: 0.3, type: 'SSD - Samsung' },
    ];

    return (
        <div className="glass-panel p-6 rounded-2xl h-full">
            <div className="flex justify-between items-center mb-6">
                <div>
                    <h3 className="text-xl font-bold flex items-center gap-2">
                        <Server className="w-6 h-6 text-snok-primary" />
                        RackStation Overview
                    </h3>
                    <p className="text-snok-muted text-sm mt-1">SnokNAS 8-Bay Unit • Model X8-Pro</p>
                </div>
                <div className="flex gap-4 text-sm">
                    <div className="flex items-center gap-2">
                        <span className="w-2 h-2 rounded-full bg-snok-success" />
                        <span>7 Healthy</span>
                    </div>
                    <div className="flex items-center gap-2">
                        <span className="w-2 h-2 rounded-full bg-snok-warning" />
                        <span>1 Warning</span>
                    </div>
                </div>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-4">
                {drives.map((drive) => (
                    <DriveBay key={drive.id} {...drive} />
                ))}
            </div>

            {/* Rack Visualization Footer */}
            <div className="mt-8 p-4 bg-black/40 rounded-xl border border-white/5 flex items-center justify-between">
                <div className="flex items-center gap-4">
                    <div className="h-2 w-2 rounded-full bg-green-500 animate-pulse shadow-[0_0_10px_rgba(34,197,94,0.5)]"></div>
                    <span className="text-xs font-mono text-green-500">SYSTEM_ONLINE</span>
                </div>
                <div className="text-xs text-snok-muted font-mono">
                    Uptime: 14d 2h 12m
                </div>
            </div>
        </div>
    );
};

export default RackStation;
