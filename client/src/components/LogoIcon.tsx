import React from "react";

export function LogoIcon({ className = "w-6 h-6" }: { className?: string }) {
  return (
    <svg 
      viewBox="0 0 100 120" 
      className={className} 
      fill="none" 
      xmlns="http://www.w3.org/2000/svg"
    >
      {/* Green lightning bolt "F" shape */}
      <path 
        d="M20 15 H80 L72 37 H46 L53 52 H75 L67 74 H41 L27 105 L37 62 H25 L32 37 H20 L20 15 Z" 
        fill="oklch(0.72 0.2 145)" 
        className="drop-shadow-[0_0_8px_rgba(34,197,94,0.5)]"
      />
      {/* Purple accent block at the bottom right */}
      <path 
        d="M50 78 H75 L67 96 H42 L50 78 Z" 
        fill="oklch(0.6 0.2 300)" 
      />
    </svg>
  );
}
