export interface StoreItem {
  id: string;
  name: string;
  description: string;
  price: number;
  type: 'skin' | 'utility';
  assetUrl?: string; // or emoji
}

export const STORE_CATALOG: StoreItem[] = [
  {
    id: "skin_headband",
    name: "Vincha de Entrenamiento",
    description: "Una vincha clásica para el sudor. ¡Estilo retro!",
    price: 150,
    type: "skin",
  },
  {
    id: "skin_sunglasses",
    name: "Anteojos de Sol",
    description: "Para entrenar con estilo y ocultar las ojeras.",
    price: 300,
    type: "skin",
  },
  {
    id: "skin_cap",
    name: "Gorra Deportiva",
    description: "Gorra hacia atrás para modo bestia.",
    price: 500,
    type: "skin",
  },
  {
    id: "utility_streak_freeze",
    name: "Protector de Racha",
    description: "Mantiene tu racha intacta si faltás un día de entrenamiento.",
    price: 200,
    type: "utility",
  }
];
