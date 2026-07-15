import { LineChart, Line, BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer, AreaChart, Area } from "recharts";
import { Card } from "@/components/ui/card";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { TrendingUp, Weight, Zap, Clock } from "lucide-react";
import { exerciseTranslations } from "@/lib/exerciseTranslations";

interface ProgressData {
  date: string;
  weight?: number;
  reps?: number;
  sets?: number;
  duration?: number;
  xp?: number;
}

interface Props {
  exerciseName: string;
  data: ProgressData[];
}

export default function ProgressGraphs({ exerciseName, data }: Props) {
  const translatedName = exerciseTranslations[exerciseName] ?? exerciseName;

  if (!data || data.length === 0) {
    return (
      <Card className="p-6 border-border/50 bg-card/50 text-center">
        <p className="text-muted-foreground">No hay datos de progreso disponibles para {translatedName}</p>
      </Card>
    );
  }

  const weightData = data.filter(d => d.weight !== undefined);
  const repsData = data.filter(d => d.reps !== undefined);
  const durationData = data.filter(d => d.duration !== undefined);
  const xpData = data.filter(d => d.xp !== undefined);

  const stats = {
    maxWeight: Math.max(...weightData.map(d => d.weight || 0)),
    avgWeight: weightData.length > 0 ? (weightData.reduce((sum, d) => sum + (d.weight || 0), 0) / weightData.length).toFixed(1) : 0,
    maxReps: Math.max(...repsData.map(d => d.reps || 0)),
    totalXP: xpData.reduce((sum, d) => sum + (d.xp || 0), 0),
  };

  return (
    <div className="space-y-4 p-4 border border-border/50 rounded-xl bg-card/30">
      <h3 className="font-semibold text-base text-foreground">{translatedName}</h3>
      <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
        {weightData.length > 0 && (
          <Card className="p-4 border-border/50">
            <div className="flex items-center gap-2 mb-2">
              <Weight className="w-4 h-4 text-accent" />
              <p className="text-xs font-semibold text-muted-foreground">Peso Máximo</p>
            </div>
            <p className="text-2xl font-bold text-foreground">{stats.maxWeight} kg</p>
            <p className="text-xs text-muted-foreground mt-1">Promedio: {stats.avgWeight} kg</p>
          </Card>
        )}

        {repsData.length > 0 && (
          <Card className="p-4 border-border/50">
            <div className="flex items-center gap-2 mb-2">
              <TrendingUp className="w-4 h-4 text-accent" />
              <p className="text-xs font-semibold text-muted-foreground">Máx. Reps</p>
            </div>
            <p className="text-2xl font-bold text-foreground">{stats.maxReps}</p>
            <p className="text-xs text-muted-foreground mt-1">Repeticiones</p>
          </Card>
        )}

        {durationData.length > 0 && (
          <Card className="p-4 border-border/50">
            <div className="flex items-center gap-2 mb-2">
              <Clock className="w-4 h-4 text-accent" />
              <p className="text-xs font-semibold text-muted-foreground">Tiempo Total</p>
            </div>
            <p className="text-2xl font-bold text-foreground">{(durationData.reduce((sum, d) => sum + (d.duration || 0), 0) / 60).toFixed(0)} min</p>
            <p className="text-xs text-muted-foreground mt-1">Acumulado</p>
          </Card>
        )}

        {xpData.length > 0 && (
          <Card className="p-4 border-border/50">
            <div className="flex items-center gap-2 mb-2">
              <Zap className="w-4 h-4 text-accent" />
              <p className="text-xs font-semibold text-muted-foreground">XP Ganado</p>
            </div>
            <p className="text-2xl font-bold text-accent">{stats.totalXP}</p>
            <p className="text-xs text-muted-foreground mt-1">Total</p>
          </Card>
        )}
      </div>

      <Tabs defaultValue="weight" className="w-full">
        <TabsList className="grid w-full grid-cols-4 bg-muted/30">
          {weightData.length > 0 && <TabsTrigger value="weight">Peso</TabsTrigger>}
          {repsData.length > 0 && <TabsTrigger value="reps">Repeticiones</TabsTrigger>}
          {durationData.length > 0 && <TabsTrigger value="duration">Duración</TabsTrigger>}
          {xpData.length > 0 && <TabsTrigger value="xp">XP</TabsTrigger>}
        </TabsList>

        {weightData.length > 0 && (
          <TabsContent value="weight" className="h-[300px] mt-4 transition-transform duration-300 hover:scale-[1.02]">
            <Card className="p-4 border-border/50 h-full">
              <ResponsiveContainer width="100%" height="100%">
                <AreaChart data={weightData} margin={{ top: 10, right: 10, left: -20, bottom: 0 }}>
                  <defs>
                    <linearGradient id="colorWeight" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="5%" stopColor="oklch(0.72 0.2 145)" stopOpacity={0.5}/>
                      <stop offset="95%" stopColor="oklch(0.72 0.2 145)" stopOpacity={0}/>
                    </linearGradient>
                  </defs>
                  <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.1)" vertical={false} />
                  <XAxis dataKey="date" stroke="rgba(255,255,255,0.5)" fontSize={12} tickLine={false} axisLine={false} />
                  <YAxis stroke="rgba(255,255,255,0.5)" fontSize={12} tickLine={false} axisLine={false} />
                  <Tooltip 
                    contentStyle={{ backgroundColor: "rgba(20,20,28,0.95)", border: "1px solid rgba(255,255,255,0.1)", borderRadius: "8px" }}
                    labelStyle={{ color: "rgba(255,255,255,0.7)" }}
                  />
                  <Area 
                    type="monotone" 
                    dataKey="weight" 
                    name="Peso (kg)" 
                    stroke="oklch(0.72 0.2 145)" 
                    strokeWidth={3} 
                    fillOpacity={1} 
                    fill="url(#colorWeight)" 
                    isAnimationActive={true}
                    animationDuration={1500}
                    activeDot={{ r: 8, strokeWidth: 2, fill: "oklch(0.72 0.2 145)" }}
                  />
                </AreaChart>
              </ResponsiveContainer>
            </Card>
          </TabsContent>
        )}

        {repsData.length > 0 && (
          <TabsContent value="reps" className="h-[300px] mt-4 transition-transform duration-300 hover:scale-[1.02]">
            <Card className="p-4 border-border/50 h-full">
              <ResponsiveContainer width="100%" height="100%">
                <BarChart data={repsData} margin={{ top: 10, right: 10, left: -20, bottom: 0 }}>
                  <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.1)" vertical={false} />
                  <XAxis dataKey="date" stroke="rgba(255,255,255,0.5)" fontSize={12} tickLine={false} axisLine={false} />
                  <YAxis stroke="rgba(255,255,255,0.5)" fontSize={12} tickLine={false} axisLine={false} />
                  <Tooltip 
                    contentStyle={{ backgroundColor: "rgba(20,20,28,0.95)", border: "1px solid rgba(255,255,255,0.1)", borderRadius: "8px" }}
                    labelStyle={{ color: "rgba(255,255,255,0.7)" }}
                    cursor={{ fill: 'rgba(255,255,255,0.1)' }}
                  />
                  <Bar 
                    dataKey="reps" 
                    name="Repeticiones" 
                    fill="oklch(0.65 0.18 200)" 
                    radius={[4, 4, 0, 0]} 
                    isAnimationActive={true}
                    animationDuration={1500}
                  />
                </BarChart>
              </ResponsiveContainer>
            </Card>
          </TabsContent>
        )}

        {durationData.length > 0 && (
          <TabsContent value="duration" className="h-[300px] mt-4 transition-transform duration-300 hover:scale-[1.02]">
            <Card className="p-4 border-border/50 h-full">
              <ResponsiveContainer width="100%" height="100%">
                <LineChart data={durationData} margin={{ top: 10, right: 10, left: -20, bottom: 0 }}>
                  <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.1)" vertical={false} />
                  <XAxis dataKey="date" stroke="rgba(255,255,255,0.5)" fontSize={12} tickLine={false} axisLine={false} />
                  <YAxis stroke="rgba(255,255,255,0.5)" fontSize={12} tickLine={false} axisLine={false} />
                  <Tooltip 
                    contentStyle={{ backgroundColor: "rgba(20,20,28,0.95)", border: "1px solid rgba(255,255,255,0.1)", borderRadius: "8px" }}
                    labelStyle={{ color: "rgba(255,255,255,0.7)" }}
                  />
                  <Line 
                    type="monotone" 
                    dataKey="duration" 
                    name="Duración (seg)" 
                    stroke="oklch(0.7 0.2 60)" 
                    strokeWidth={3} 
                    dot={{ fill: "oklch(0.7 0.2 60)", r: 4 }} 
                    isAnimationActive={true}
                    animationDuration={1500}
                    activeDot={{ r: 8, strokeWidth: 2, fill: "oklch(0.7 0.2 60)" }}
                  />
                </LineChart>
              </ResponsiveContainer>
            </Card>
          </TabsContent>
        )}

        {xpData.length > 0 && (
          <TabsContent value="xp" className="h-[300px] mt-4 transition-transform duration-300 hover:scale-[1.02]">
            <Card className="p-4 border-border/50 h-full">
              <ResponsiveContainer width="100%" height="100%">
                <AreaChart data={xpData} margin={{ top: 10, right: 10, left: -20, bottom: 0 }}>
                  <defs>
                    <linearGradient id="colorXp" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="5%" stopColor="oklch(0.65 0.2 300)" stopOpacity={0.5}/>
                      <stop offset="95%" stopColor="oklch(0.65 0.2 300)" stopOpacity={0}/>
                    </linearGradient>
                  </defs>
                  <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.1)" vertical={false} />
                  <XAxis dataKey="date" stroke="rgba(255,255,255,0.5)" fontSize={12} tickLine={false} axisLine={false} />
                  <YAxis stroke="rgba(255,255,255,0.5)" fontSize={12} tickLine={false} axisLine={false} />
                  <Tooltip 
                    contentStyle={{ backgroundColor: "rgba(20,20,28,0.95)", border: "1px solid rgba(255,255,255,0.1)", borderRadius: "8px" }}
                    labelStyle={{ color: "rgba(255,255,255,0.7)" }}
                  />
                  <Area 
                    type="monotone" 
                    dataKey="xp" 
                    name="XP Ganado" 
                    stroke="oklch(0.65 0.2 300)" 
                    strokeWidth={3} 
                    fillOpacity={1} 
                    fill="url(#colorXp)" 
                    isAnimationActive={true}
                    animationDuration={1500}
                    activeDot={{ r: 8, strokeWidth: 2, fill: "oklch(0.65 0.2 300)" }}
                  />
                </AreaChart>
              </ResponsiveContainer>
            </Card>
          </TabsContent>
        )}
      </Tabs>
    </div>
  );
}
