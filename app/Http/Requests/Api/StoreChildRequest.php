<?php

namespace App\Http\Requests\Api;

use Illuminate\Foundation\Http\FormRequest;

class StoreChildRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     */
    public function authorize(): bool
    {
        return true;
    }

    /**
     * Get the validation rules that apply to the request.
     *
     * @return array<string, \Illuminate\Contracts\Validation\ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
        return [
            'name' => ['required', 'string', 'max:100'],
            'birth_date' => ['nullable', 'date'],
            'avatar_key' => ['nullable', 'string', 'max:50'],
            'reading_level' => ['nullable', 'string', 'max:50'],
            'accessibility_settings' => ['nullable', 'array'],
        ];
    }

    /**
     * Get custom error messages for validator errors.
     *
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'name.required' => 'El nombre del niño o niña es obligatorio.',
            'birth_date.date' => 'La fecha de nacimiento no tiene un formato válido.',
        ];
    }
}
