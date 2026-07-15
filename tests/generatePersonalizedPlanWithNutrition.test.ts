import { generatePersonalizedPlanWithNutrition } from '../server/routers';
import { generateBasicPlan } from '../server/routers';
import { invokeLLM } from '../server/_core/llm';

jest.mock('../server/_core/llm', () => ({
  invokeLLM: jest.fn().mockRejectedValue(new Error('LLM API down')),
}));

jest.mock('../server/routers', () => {
  const originalModule = jest.requireActual('../server/routers');
  return {
    ...originalModule,
    generateBasicPlan: jest.fn().mockResolvedValue({
      generatedContent: JSON.stringify({
        days: [
          { dayNumber: 1, focus: 'Full Body', warmup: 'Mobility', exercises: [], cooldown: '', notes: '' },
        ],
        nutrition: {},
      }),
    }),
  };
});

describe('generatePersonalizedPlanWithNutrition fallback', () => {
  it('should use basic plan when LLM fails', async () => {
    const input = {
      objective: 'fat_loss',
      experienceLevel: 'beginner',
      age: 45,
      weight: 90,
      height: 175,
      daysPerWeek: 3,
      equipment: 'bodyweight',
      injuries: 'wrist',
      preferences: undefined,
    };
    const result = await generatePersonalizedPlanWithNutrition(input);
    const parsed = JSON.parse(result.generatedContent);
    expect(parsed.days).toBeDefined();
    expect(parsed.days.length).toBeGreaterThan(0);
    // Ensure fallback was called
    expect(generateBasicPlan).toHaveBeenCalled();
  });
});
