import React from "react";
import { PostureCamera } from "../components/PostureCamera";

export const PostureTest: React.FC = () => {
  return (
    <div style={{ padding: "20px" }}>
      <h1>Prueba de Corrección de Postura</h1>
      <p>Ejercicio: Sentadilla</p>
      <PostureCamera exerciseId="sentadilla" />
    </div>
  );
};