<?php

namespace App\Http\Requests\Api;

use Illuminate\Foundation\Http\FormRequest;

class SyncProgressRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     */
    public function authorize(): bool
    {
        return true;
    }

    /**
     * Prepare data for validation to handle both top-level arrays and `{ events: [...] }` envelopes.
     */
    protected function prepareForValidation(): void
    {
        $input = $this->all();

        // Si el cliente envía directamente un array [ { ... }, { ... } ]
        if (array_is_list($input)) {
            $this->merge(['events' => $input]);
        }
    }

    /**
     * Get the validation rules that apply to the request.
     *
     * @return array<string, \Illuminate\Contracts\Validation\ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
        return [
            'events' => ['required', 'array', 'min:1'],
            'events.*.child_id' => ['required', 'integer'],
            'events.*.activity_id' => ['required', 'string', 'max:100'],
            'events.*.score' => ['required', 'numeric'],
            'events.*.stars' => ['nullable', 'integer', 'min:0', 'max:5'],
            'events.*.metadata' => ['nullable', 'array'],
            'events.*.updated_at' => ['required', 'date'],
            'events.*.deleted_at' => ['nullable', 'date'],
        ];
    }

    /**
     * Get custom error messages for validation failures.
     *
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'events.required' => 'El lote de eventos de progreso es obligatorio.',
            'events.array' => 'El lote de eventos debe ser un arreglo de elementos.',
            'events.*.child_id.required' => 'Cada evento debe incluir el ID del niño (child_id).',
            'events.*.activity_id.required' => 'Cada evento debe especificar el identificador de la actividad (activity_id).',
            'events.*.score.required' => 'La puntuación (score) es obligatoria.',
            'events.*.updated_at.required' => 'La marca de tiempo de actualización (updated_at) es obligatoria para la resolución de conflictos.',
        ];
    }
}
