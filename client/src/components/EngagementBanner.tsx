import { useEffect, useState } from "react";
import { trpc } from "@/lib/trpc";
import { X } from "lucide-react";
import { useLocation } from "wouter";
import { cn } from "@/lib/utils";

type Alert = {
  id: string;
  type: string;
  emoji: string;
  title: string;
  body: string;
  cta: string;
  action: "open_workout" | "open_dashboard" | "create_plan";
  dismissible: boolean;
};

function accentFor(type: string) {
  switch (type) {
    case "missed_you":
      return "from-pink-500/25 border-pink-400/40 text-pink-200";
    case "streak_at_risk":
    case "keep_streak":
      return "from-orange-500/25 border-orange-400/40 text-orange-200";
    case "close_to_level":
    case "close_to_streak_goal":
      return "from-amber-500/25 border-amber-400/40 text-amber-200";
    case "no_plan":
      return "from-violet-500/25 border-violet-400/40 text-violet-200";
    default:
      return "from-emerald-500/25 border-emerald-400/40 text-emerald-200";
  }
}

/** Pose de la mascota rayo según tipo de alerta */
function mascotSrc(type: string) {
  switch (type) {
    case "missed_you":
      return "/mascot/mascot_miss_you.jpg";
    case "streak_at_risk":
    case "keep_streak":
      return "/mascot/mascot_streak.jpg";
    case "close_to_level":
    case "close_to_streak_goal":
      return "/mascot/mascot_goal.jpg";
    case "no_plan":
    case "daily_nudge":
      return "/mascot/mascot_idle.jpg";
    default:
      return "/mascot/mascot_happy.jpg";
  }
}

function todayKey() {
  return new Date().toISOString().slice(0, 10);
}

export function EngagementBanner({ onCreatePlan }: { onCreatePlan?: () => void }) {
  const [, navigate] = useLocation();
  const { data } = trpc.engagement.getAlerts.useQuery(undefined, {
    staleTime: 60_000,
    refetchOnWindowFocus: true,
  });
  const [dismissedId, setDismissedId] = useState<string | null>(null);

  useEffect(() => {
    try {
      const raw = localStorage.getItem("ferfit_engagement_dismissed");
      if (!raw) return;
      const parsed = JSON.parse(raw) as { id: string; day: string };
      if (parsed.day === todayKey()) setDismissedId(parsed.id);
    } catch {
      /* ignore */
    }
  }, []);

  const alert = (data?.primary ?? data?.alerts?.[0] ?? null) as Alert | null;
  if (!alert || dismissedId === alert.id) return null;

  const handleDismiss = () => {
    setDismissedId(alert.id);
    try {
      localStorage.setItem(
        "ferfit_engagement_dismissed",
        JSON.stringify({ id: alert.id, day: todayKey() })
      );
    } catch {
      /* ignore */
    }
  };

  const handleCta = () => {
    if (alert.action === "create_plan") {
      onCreatePlan?.();
      return;
    }
    if (alert.action === "open_workout") {
      navigate("/entrenamiento");
      return;
    }
    navigate("/dashboard");
  };

  return (
    <div
      className={cn(
        "relative mb-6 rounded-2xl border bg-gradient-to-br to-card/90 p-4 sm:p-5 shadow-[0_0_24px_oklch(0.72_0.2_145/0.08)]",
        accentFor(alert.type)
      )}
    >
      <div className="flex gap-3 sm:gap-4">
        <div className="relative flex h-16 w-16 shrink-0 items-center justify-center rounded-full bg-black/60 border border-accent/30 shadow-[0_0_16px_oklch(0.72_0.2_145/0.25)] overflow-hidden">
          <img
            src={mascotSrc(alert.type)}
            alt="Feo, mascota de FerFit"
            className="h-full w-full object-cover animate-[feo-float_2s_ease-in-out_infinite]"
            onError={(e) => {
              (e.currentTarget as HTMLImageElement).src = "/mascot/ferfit_mascot.jpg";
            }}
          />
        </div>
        <div className="min-w-0 flex-1 pr-6">
          <p className="text-[10px] font-semibold uppercase tracking-wider text-accent mb-0.5">Feo</p>
          <h3 className="font-display text-lg sm:text-xl font-bold text-foreground leading-tight">
            {alert.title}
          </h3>
          <p className="mt-1 text-sm text-muted-foreground leading-relaxed">{alert.body}</p>
          <button
            type="button"
            onClick={handleCta}
            className="mt-3 inline-flex items-center rounded-full bg-accent px-4 py-1.5 text-sm font-semibold text-accent-foreground hover:opacity-90 transition"
          >
            {alert.cta}
          </button>
        </div>
        {alert.dismissible && (
          <button
            type="button"
            onClick={handleDismiss}
            className="absolute right-3 top-3 rounded-lg p-1 text-muted-foreground hover:text-foreground hover:bg-muted/40"
            aria-label="Cerrar"
          >
            <X className="h-4 w-4" />
          </button>
        )}
      </div>
    </div>
  );
}
