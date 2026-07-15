import { useUser, useClerk } from "@clerk/clerk-react";
import { Avatar, AvatarFallback } from "@/components/ui/avatar";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { useIsMobile } from "@/hooks/useMobile";
import { LayoutDashboard, LogOut, Dumbbell, Apple, TrendingUp, MessageSquare } from "lucide-react";
import { useLocation } from "wouter";
import { LogoIcon } from "@/components/LogoIcon";
import { trpc } from "@/lib/trpc";

const menuItems = [
  { icon: LayoutDashboard, label: "Dashboard", path: "/dashboard" },
  { icon: Dumbbell, label: "Entrenamiento", path: "/entrenamiento" },
  { icon: Apple, label: "Nutrición", path: "/nutricion" },
  { icon: TrendingUp, label: "Progreso", path: "/progreso" },
  { icon: MessageSquare, label: "Feo", path: "/feo" },
];

export default function DashboardLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const { user } = useUser();
  const { signOut } = useClerk();
  const [location, setLocation] = useLocation();
  const isMobile = useIsMobile();
  const { data: progress } = trpc.training.getUserProgress.useQuery();

  return (
    <div className="min-h-screen bg-transparent flex flex-col">
      {/* Top Header Navigation (Desktop only) */}
      {!isMobile && (
        <header className="sticky top-0 z-50 w-full border-b border-border/10 bg-background/30 backdrop-blur-md">
          <div className="container flex h-16 items-center justify-between mx-auto px-6">
            <div className="flex items-center gap-8">
              <div className="flex items-center gap-2.5">
                <LogoIcon className="h-8 w-8" />
                <div className="space-y-0.5">
                  <h1 className="text-2xl font-bold tracking-tight leading-none font-display">
                    Fer<span className="text-accent">Fit</span>
                  </h1>
                  <p className="text-[10px] text-muted-foreground uppercase tracking-wider font-semibold">
                    AI Fitness
                  </p>
                </div>
              </div>
              
              <nav className="flex items-center gap-1.5">
                {menuItems.map(item => {
                  const isActive = location === item.path;
                  return (
                    <button
                      key={item.path}
                      onClick={() => setLocation(item.path)}
                      className={`px-4 py-2 rounded-xl text-sm font-medium transition-all ${
                        isActive
                          ? "text-accent bg-accent/15 border border-accent/20 shadow-[0_0_15px_oklch(0.72_0.2_145/0.1)]"
                          : "text-muted-foreground hover:text-foreground hover:bg-muted/40"
                      }`}
                    >
                      {item.label}
                    </button>
                  );
                })}
              </nav>
            </div>

            <div className="flex items-center gap-4">
              <DropdownMenu>
                <DropdownMenuTrigger asChild>
                  <button className="flex items-center gap-3 rounded-xl px-2.5 py-1.5 hover:bg-muted/40 transition-colors text-left focus:outline-none border border-transparent hover:border-border/30">
                    <Avatar className="h-8 w-8 border border-accent/20">
                      <AvatarFallback className="text-xs font-semibold bg-accent/10 text-accent">
                        {(user?.firstName || user?.username || "U")?.charAt(0).toUpperCase()}
                      </AvatarFallback>
                    </Avatar>
                    <div className="text-xs">
                      <p className="font-semibold text-foreground leading-none">
                        {user?.firstName || user?.username || "-"}
                      </p>
                      <p className="text-[10px] text-muted-foreground mt-1">
                        Nivel {progress?.level || 1} / Atleta
                      </p>
                    </div>
                  </button>
                </DropdownMenuTrigger>
                <DropdownMenuContent align="end" className="w-48 glass-panel">
                  <DropdownMenuItem
                    onClick={() => signOut()}
                    className="cursor-pointer text-destructive focus:text-destructive"
                  >
                    <LogOut className="mr-2 h-4 w-4" />
                    <span>Cerrar Sesión</span>
                  </DropdownMenuItem>
                </DropdownMenuContent>
              </DropdownMenu>
            </div>
          </div>
        </header>
      )}

      {/* Main Content Area */}
      <main className={`flex-1 p-4 md:p-8 mx-auto w-full max-w-7xl ${isMobile ? "pb-24" : "pb-12"}`}>
        {children}
      </main>

      {/* Bottom Navigation for Mobile */}
      {isMobile && (
        <div className="fixed bottom-0 left-0 right-0 h-16 bg-background/90 border-t border-border/50 backdrop-blur supports-[backdrop-filter]:backdrop-blur flex items-center justify-around px-2 z-50 pb-safe">
          {menuItems.map(item => {
            const isActive = location === item.path;
            const Icon = item.icon;
            return (
              <button
                key={item.path}
                onClick={() => setLocation(item.path)}
                className={`flex flex-col items-center justify-center gap-1 flex-1 h-full text-center transition-all ${
                  isActive ? "text-accent" : "text-muted-foreground hover:text-foreground"
                }`}
              >
                <Icon className="h-5 w-5" />
                <span className="text-[10px] font-medium tracking-tight">{item.label}</span>
              </button>
            );
          })}
          
          <button
            onClick={() => {
              if (confirm("¿Estás seguro de que deseas cerrar sesión?")) {
                signOut();
              }
            }}
            className="flex flex-col items-center justify-center gap-1 flex-1 h-full text-center text-muted-foreground hover:text-foreground transition-all"
          >
            <div className="w-5 h-5 rounded-full border border-border/60 overflow-hidden flex items-center justify-center bg-muted/30">
              {user?.imageUrl ? (
                <img src={user.imageUrl} alt="Avatar" className="w-full h-full object-cover" />
              ) : (
                <Avatar className="h-full w-full">
                  <AvatarFallback className="text-[10px] font-bold">
                    {(user?.firstName || user?.username || "U")?.charAt(0).toUpperCase()}
                  </AvatarFallback>
                </Avatar>
              )}
            </div>
            <span className="text-[10px] font-medium tracking-tight">Salir</span>
          </button>
        </div>
      )}
    </div>
  );
}