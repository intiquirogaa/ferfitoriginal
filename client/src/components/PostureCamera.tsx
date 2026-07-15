import React, { useEffect, useRef, useState } from "react";
import { Pose } from "@mediapipe/pose";

interface PostureCameraProps {
  exerciseId: string; // Ej: "sentadilla"
}

interface IdealPosture {
  joints: Record<string, { x: number; y: number }>;
  angles: Record<string, { min: number; max: number; feedback: string }>;
}

export const PostureCamera: React.FC<PostureCameraProps> = ({ exerciseId }) => {
  const videoRef = useRef<HTMLVideoElement>(null);
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const [feedback, setFeedback] = useState<string[]>([]);
  const [isLoading, setIsLoading] = useState(false); // Cambiado a false
  const [idealPosture, setIdealPosture] = useState<IdealPosture | null>(null);
  const [cameraActive, setCameraActive] = useState(false); // Estado de la cámara
  const [instructions, setInstructions] = useState<string>(
    "Coloca la cámara a 2 metros de distancia, en un ángulo frontal o lateral, para analizar tu postura correctamente."
  );
  const inactivityTimeout = useRef<NodeJS.Timeout | null>(null);

  // Cargar postura ideal desde JSON
  useEffect(() => {
    const loadIdealPosture = async () => {
      try {
        const response = await fetch(`/exercises/${exerciseId}.json`);
        if (!response.ok) {
          throw new Error("Postura ideal no encontrada");
        }
        const data = await response.json();
        setIdealPosture(data);
      } catch (error) {
        console.error("Error al cargar postura ideal:", error);
        setFeedback(["No se pudo cargar la postura ideal para este ejercicio."]);
      }
    };
    loadIdealPosture();
  }, [exerciseId]);

  // Manejar inactividad
  const resetInactivityTimeout = () => {
    if (inactivityTimeout.current) {
      clearTimeout(inactivityTimeout.current);
    }
    inactivityTimeout.current = setTimeout(() => {
      stopCamera();
      setInstructions("La cámara se ha desactivado por inactividad. Haz clic en 'Iniciar Análisis' para volver a activarla.");
    }, 30000); // 30 segundos de inactividad
  };

  const startCamera = async () => {
    try {
      setIsLoading(true);
      setInstructions("Analizando postura...");
      setFeedback([]);
      
      // 1. Acceder a la cámara
      const stream = await navigator.mediaDevices.getUserMedia({
        video: { width: 640, height: 480, frameRate: 15 }
      });
      if (videoRef.current) {
        videoRef.current.srcObject = stream;
      }

      // 2. Configurar MediaPipe
      const pose = new Pose({
        locateFile: (file) => `https://cdn.jsdelivr.net/npm/@mediapipe/pose/${file}`,
      });
      pose.setOptions({
        modelComplexity: 1,
        smoothLandmarks: true,
        minDetectionConfidence: 0.5,
        minTrackingConfidence: 0.5,
      });

      // 3. Procesar frames
      pose.onResults((results) => {
        if (canvasRef.current && videoRef.current && idealPosture) {
          const canvas = canvasRef.current;
          const ctx = canvas.getContext("2d");
          if (ctx) {
            // Dibujar video en canvas
            ctx.drawImage(videoRef.current, 0, 0, canvas.width, canvas.height);
            // Dibujar landmarks (esqueleto)
            drawLandmarks(ctx, results.poseLandmarks);
            // Comparar con postura ideal y mostrar feedback
            const postureFeedback = compareWithIdealPosture(results.poseLandmarks, idealPosture);
            setFeedback(postureFeedback);
            // Reiniciar temporizador de inactividad
            resetInactivityTimeout();
          }
        }
      });

      // 4. Iniciar procesamiento
      const processFrame = async () => {
        if (videoRef.current && cameraActive) {
          await pose.send({ image: videoRef.current });
        }
        requestAnimationFrame(processFrame);
      };
      processFrame();

      setCameraActive(true);
      setIsLoading(false);
    } catch (error) {
      console.error("Error al iniciar la cámara:", error);
      setFeedback(["No se pudo acceder a la cámara. Verifica los permisos."]);
      setIsLoading(false);
    }
  };

  const stopCamera = () => {
    if (videoRef.current?.srcObject) {
      const stream = videoRef.current.srcObject as MediaStream;
      stream.getTracks().forEach(track => track.stop());
      videoRef.current.srcObject = null;
    }
    setCameraActive(false);
    if (inactivityTimeout.current) {
      clearTimeout(inactivityTimeout.current);
    }
  };

  // Iniciar cámara solo cuando el usuario haga clic en el botón
  useEffect(() => {
    return () => {
      stopCamera();
    };
  }, [idealPosture]);

  const drawLandmarks = (ctx: CanvasRenderingContext2D, landmarks: any[]) => {
    if (!landmarks || landmarks.length === 0) return;

    // Dibujar líneas entre articulaciones (ej: hombro -> codo)
    const connections = [
      [11, 13], // Hombro izquierdo -> Codo izquierdo
      [13, 15], // Codo izquierdo -> Muñeca izquierda
      [12, 14], // Hombro derecho -> Codo derecho
      [14, 16], // Codo derecho -> Muñeca derecha
      [23, 25], // Cadera izquierda -> Rodilla izquierda
      [25, 27], // Rodilla izquierda -> Tobillo izquierdo
      [24, 26], // Cadera derecha -> Rodilla derecha
      [26, 28], // Rodilla derecha -> Tobillo derecho
      [11, 12], // Hombro izquierdo -> Hombro derecho
      [23, 24], // Cadera izquierda -> Cadera derecha
    ];

    ctx.strokeStyle = "green";
    ctx.lineWidth = 3;

    connections.forEach(([startIdx, endIdx]) => {
      const start = landmarks[startIdx];
      const end = landmarks[endIdx];
      if (start && end) {
        ctx.beginPath();
        ctx.moveTo(start.x * ctx.canvas.width, start.y * ctx.canvas.height);
        ctx.lineTo(end.x * ctx.canvas.width, end.y * ctx.canvas.height);
        ctx.stroke();
      }
    });
  };

  const compareWithIdealPosture = (landmarks: any[], idealPosture: IdealPosture): string[] => {
    const feedback: string[] = [];
    if (!landmarks || landmarks.length === 0) return feedback;

    // Comparar ángulos
    Object.entries(idealPosture.angles).forEach(([angleName, angleData]) => {
      // Calcular ángulo real (ej: ángulo de rodilla)
      let realAngle = 0;
      if (angleName === "knee") {
        // Ángulo entre cadera, rodilla y tobillo (ej: landmarks 23, 25, 27 para pierna izquierda)
        const hip = landmarks[23];
        const knee = landmarks[25];
        const ankle = landmarks[27];
        if (hip && knee && ankle) {
          realAngle = calculateAngle(hip, knee, ankle);
        }
      } else if (angleName === "back") {
        // Ángulo entre hombro, cadera y rodilla
        const shoulder = landmarks[11];
        const hip = landmarks[23];
        const knee = landmarks[25];
        if (shoulder && hip && knee) {
          realAngle = calculateAngle(shoulder, hip, knee);
        }
      }

      // Verificar si el ángulo está fuera del rango ideal
      if (realAngle < angleData.min || realAngle > angleData.max) {
        feedback.push(angleData.feedback);
      }
    });

    return feedback;
  };

  const calculateAngle = (a: any, b: any, c: any): number => {
    // Convertir landmarks a vectores
    const vectorAB = { x: b.x - a.x, y: b.y - a.y };
    const vectorBC = { x: b.x - c.x, y: b.y - c.y };

    // Calcular ángulo en radianes y convertir a grados
    const dotProduct = vectorAB.x * vectorBC.x + vectorAB.y * vectorBC.y;
    const magnitudeAB = Math.sqrt(vectorAB.x ** 2 + vectorAB.y ** 2);
    const magnitudeBC = Math.sqrt(vectorBC.x ** 2 + vectorBC.y ** 2);
    const angleRad = Math.acos(dotProduct / (magnitudeAB * magnitudeBC));
    const angleDeg = angleRad * (180 / Math.PI);

    return angleDeg;
  };

  const capturePosture = () => {
    if (canvasRef.current && idealPosture) {
      const canvas = canvasRef.current;
      const ctx = canvas.getContext("2d");
      if (ctx) {
        // Dibujar el video en el canvas
        ctx.drawImage(videoRef.current!, 0, 0, canvas.width, canvas.height);
        // Analizar la postura actual
        const imageData = canvas.toDataURL("image/jpeg");
        const img = new Image();
        img.src = imageData;
        img.onload = async () => {
          // Simular procesamiento con MediaPipe (en un caso real, enviar al backend)
          const mockLandmarks = await mockMediaPipeDetection(img);
          const postureFeedback = compareWithIdealPosture(mockLandmarks, idealPosture);
          setFeedback(postureFeedback);
          // Dibujar landmarks en el canvas
          drawLandmarks(ctx, mockLandmarks);
        };
      }
    }
  };

  // Mock de MediaPipe para simular detección (reemplazar con llamada real)
  const mockMediaPipeDetection = async (image: HTMLImageElement): Promise<any[]> => {
    // En un caso real, aquí iría la llamada a MediaPipe
    // Simulamos landmarks para una sentadilla
    return [
      { x: 0.4, y: 0.3, name: "shoulder_left" }, // Hombro izquierdo
      { x: 0.6, y: 0.3, name: "shoulder_right" }, // Hombro derecho
      { x: 0.45, y: 0.7, name: "knee_left" }, // Rodilla izquierda
      { x: 0.55, y: 0.7, name: "knee_right" }, // Rodilla derecha
      { x: 0.4, y: 0.5, name: "hip_left" }, // Cadera izquierda
      { x: 0.6, y: 0.5, name: "hip_right" }, // Cadera derecha
    ];
  };

  return (
    <div style={{ 
      position: "relative", 
      width: "640px", 
      height: "480px", 
      border: cameraActive ? "2px solid green" : "2px solid #ccc", 
      borderRadius: "4px",
      padding: "10px",
      textAlign: "center"
    }}>
      {isLoading && <p>Cargando cámara...</p>}
      {!cameraActive && !isLoading && (
        <div>
          <p style={{ marginBottom: "10px", color: "#666" }}>{instructions}</p>
          <button
            onClick={startCamera}
            style={{ 
              padding: "10px 20px",
              backgroundColor: "#007bff",
              color: "white",
              border: "none",
              borderRadius: "4px",
              cursor: "pointer",
              fontSize: "16px"
            }}
          >
            Iniciar Análisis
          </button>
        </div>
      )}
      <video
        ref={videoRef}
        autoPlay
        playsInline
        style={{ display: cameraActive ? "block" : "none", width: "100%" }}
      />
      <canvas
        ref={canvasRef}
        width={640}
        height={480}
        style={{ 
          position: "absolute", 
          top: "10px", 
          left: "10px", 
          display: cameraActive ? "block" : "none"
        }}
      />
      <div style={{ marginTop: "10px" }}>
        {feedback.map((tip, index) => (
          <p key={index} style={{ color: "red", margin: "5px 0" }}>{tip}</p>
        ))}
        {cameraActive && (
          <button
            onClick={stopCamera}
            style={{ 
              marginTop: "10px",
              padding: "8px 16px",
              backgroundColor: "#dc3545",
              color: "white",
              border: "none",
              borderRadius: "4px",
              cursor: "pointer"
            }}
          >
            Detener Análisis
          </button>
        )}
      </div>
    </div>
  );
};