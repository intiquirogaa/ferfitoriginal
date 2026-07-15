import { useState, useEffect } from "react";
import { Card } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { ChevronLeft, ChevronRight } from "lucide-react";

export interface CalendarDay {
  date: Date;
  isPadding: boolean;
  isTrainingDay: boolean;
  focus?: string;
  exercises?: Array<{
    name: string;
    sets: number | string;
    reps: string;
  }>;
  completed?: boolean;
  xpEarned?: number;
  completedSeries?: number;
  totalSeries?: number;
}

interface Props {
  calendarDays: CalendarDay[];
  onDayClick?: (day: CalendarDay) => void;
  selectedDay: CalendarDay | null;
}

function DayIndicator({ isTrainingDay, completed, percent, isSelected, dayNum }: {
  isTrainingDay: boolean;
  completed?: boolean;
  percent: number;
  isSelected: boolean;
  dayNum: number;
}) {
  const size = 32;
  const radius = 12;
  const center = size / 2;
  const circumference = 2 * Math.PI * radius;
  const strokeOffset = circumference * (1 - percent / 100);

  return (
    <div className={`relative w-9 h-9 flex items-center justify-center rounded-full transition-all ${
      isSelected 
        ? "ring-2 ring-accent ring-offset-2 ring-offset-background/10 scale-105" 
        : "hover:bg-muted/10"
    }`}>
      <svg width={size} height={size} className="transform -rotate-90 overflow-visible">
        {/* Background track circle */}
        <circle 
          cx={center} 
          cy={center} 
          r={radius} 
          fill="none" 
          stroke={isTrainingDay ? "rgba(255,255,255,0.05)" : "none"} 
          strokeWidth="3" 
        />
        {/* Active progress indicator ring */}
        {isTrainingDay && (
          <circle 
            cx={center} 
            cy={center} 
            r={radius} 
            fill="none" 
            stroke={completed ? "oklch(0.72 0.2 145)" : percent > 0 ? "oklch(0.79 0.15 85)" : "oklch(0.6 0.2 300)"} 
            strokeWidth="3" 
            strokeDasharray={circumference}
            strokeDashoffset={completed ? 0 : percent > 0 ? strokeOffset : circumference * 0.9} // show tiny slice for 0% to indicate program
            strokeLinecap="round"
            className="transition-all duration-300"
          />
        )}
        {/* Rest day indicator */}
        {!isTrainingDay && (
          <circle 
            cx={center} 
            cy={center} 
            r="3" 
            fill="rgba(255,255,255,0.15)" 
          />
        )}
      </svg>
      {/* Day number centered inside the ring */}
      <span className={`absolute text-[9px] font-bold ${
        isSelected 
          ? "text-accent" 
          : isTrainingDay 
            ? completed 
              ? "text-green-400" 
              : "text-foreground"
            : "text-muted-foreground/60"
      }`}>
        {dayNum}
      </span>
    </div>
  );
}

export default function TrainingCalendar({ calendarDays, onDayClick, selectedDay }: Props) {
  const [currentMonth, setCurrentMonth] = useState(new Date());
  const [daysInMonth, setDaysInMonth] = useState<CalendarDay[]>([]);

  useEffect(() => {
    const year = currentMonth.getFullYear();
    const month = currentMonth.getMonth();
    
    const firstDay = new Date(year, month, 1);
    const lastDay = new Date(year, month + 1, 0);
    const daysInPrevMonth = firstDay.getDay();
    const daysInCurrentMonth = lastDay.getDate();

    const days: CalendarDay[] = [];

    // Padding for previous month
    for (let i = 0; i < daysInPrevMonth; i++) {
      days.push({
        date: new Date(year, month, -i), // dummy date
        isPadding: true,
        isTrainingDay: false,
      });
    }

    // Days of current month
    for (let day = 1; day <= daysInCurrentMonth; day++) {
      const date = new Date(year, month, day);
      
      const match = calendarDays.find(cd => {
        const cdDate = new Date(cd.date);
        return cdDate.toDateString() === date.toDateString();
      });

      if (match) {
        days.push({
          ...match,
          isPadding: false,
        });
      } else {
        days.push({
          date,
          isPadding: false,
          isTrainingDay: false,
        });
      }
    }

    setDaysInMonth(days);
  }, [currentMonth, calendarDays]);

  const monthName = currentMonth.toLocaleString("es-ES", { month: "long", year: "numeric" });
  const weekDays = ["D", "L", "M", "M", "J", "V", "S"];

  return (
    <div className="space-y-4">
      {/* Navigator header */}
      <div className="flex items-center justify-between">
        <h3 className="font-display text-base font-bold text-foreground capitalize">{monthName}</h3>
        <div className="flex gap-1.5">
          <Button
            variant="ghost"
            size="icon"
            className="w-7 h-7 rounded-full border border-border/10 hover:bg-muted/10"
            onClick={() => setCurrentMonth(new Date(currentMonth.getFullYear(), currentMonth.getMonth() - 1))}
          >
            <ChevronLeft className="w-3.5 h-3.5" />
          </Button>
          <Button
            variant="ghost"
            className="h-7 text-xs font-semibold px-2 border border-border/10 hover:bg-muted/10 rounded-lg"
            onClick={() => setCurrentMonth(new Date())}
          >
            Hoy
          </Button>
          <Button
            variant="ghost"
            size="icon"
            className="w-7 h-7 rounded-full border border-border/10 hover:bg-muted/10"
            onClick={() => setCurrentMonth(new Date(currentMonth.getFullYear(), currentMonth.getMonth() + 1))}
          >
            <ChevronRight className="w-3.5 h-3.5" />
          </Button>
        </div>
      </div>

      {/* Grid structure */}
      <div className="grid grid-cols-7 gap-1">
        {weekDays.map((day, idx) => (
          <div key={idx} className="text-center text-[10px] font-bold text-muted-foreground/60 py-1 uppercase">
            {day}
          </div>
        ))}

        {daysInMonth.map((day, idx) => {
          if (day.isPadding) {
            return <div key={idx} className="w-9 h-9" />;
          }

          const isSelected = !!(selectedDay && selectedDay.date.toDateString() === day.date.toDateString());
          const percent = day.totalSeries && day.totalSeries > 0 
            ? Math.round(((day.completedSeries || 0) / day.totalSeries) * 100) 
            : 0;

          return (
            <div 
              key={idx} 
              className="flex justify-center items-center cursor-pointer"
              onClick={() => onDayClick?.(day)}
            >
              <DayIndicator
                isTrainingDay={day.isTrainingDay}
                completed={day.completed}
                percent={percent}
                isSelected={isSelected}
                dayNum={day.date.getDate()}
              />
            </div>
          );
        })}
      </div>
    </div>
  );
}
