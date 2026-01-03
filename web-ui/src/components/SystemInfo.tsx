import React from 'react';
import { Cpu, Zap, Activity, Clock } from 'lucide-react';

const InfoCard = ({ icon: Icon, label, value, subtext, color }: any) => (
    <div className="glass-card p-4 rounded-xl flex items-center gap-4 relative overflow-hidden group">
        <div className={`p-3 rounded-xl bg-snok-bg border border-white/5 group-hover:scale-110 transition-transform duration-300 ${color}`}>
            <Icon className="w-6 h-6" />
        </div>

        <div className="z-10">
            <p className="text-sm text-snok-muted">{label}</p>
            <h4 className="text-xl font-bold">{value}</h4>
            {subtext && <p className="text-xs text-snok-primary">{subtext}</p>}
        </div>

        {/* Decorative background glow */}
        <div className={`absolute -right-4 -bottom-4 w-24 h-24 bg-gradient-to-br from-white/5 to-transparent rounded-full blur-2xl group-hover:bg-white/10 transition-colors`} />
    </div>
);

const SystemInfo = () => {
    return (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
            <InfoCard
                icon={Cpu}
                label="CPU Usage"
                value="12%"
                subtext="Intel Xeon Gold"
                color="text-snok-primary"
            />
            <InfoCard
                icon={Zap}
                label="RAM Usage"
                value="8.4 GB"
                subtext="of 64 GB Total"
                color="text-snok-accent"
            />
            <InfoCard
                icon={Activity}
                label="Network Traffic"
                value="1.2 Gbps"
                subtext="Combined Throughput"
                color="text-snok-success"
            />
            <InfoCard
                icon={Clock}
                label="System Uptime"
                value="14 Days"
                subtext="Since last update"
                color="text-snok-warning"
            />
        </div>
    );
};

export default SystemInfo;
