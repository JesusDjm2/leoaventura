<?php

namespace Tests\Unit;

use App\Support\Observability\CrashReporter;
use App\Support\Observability\InMemoryCrashTransport;
use App\Support\Observability\PiiScrubber;
use App\Support\Observability\SentryHttpTransport;
use Illuminate\Support\Facades\Http;
use RuntimeException;
use Tests\TestCase;

class CrashReportingScrubberTest extends TestCase
{
    public function test_scrubber_replaces_name_and_email_with_redacted_before_sending(): void
    {
        $testPanel = new InMemoryCrashTransport();
        $reporter = new CrashReporter(
            transport: $testPanel,
            scrubber: new PiiScrubber(),
            environment: 'testing',
            release: 'leo-parvulos@1.0.0',
        );

        $exception = new RuntimeException(
            'Fallo al sincronizar perfil de nombre: Mateo González con correo papa.mateo@ejemplo.com'
        );

        $sentEvent = $reporter->captureException(
            exception: $exception,
            privacyConsentAccepted: true,
            extra: [
                'child_name' => 'Mateo González',
                'email' => 'papa.mateo@ejemplo.com',
                'device_id' => 'pixel-9988',
                'ip_address' => '192.168.1.45',
                'activity_code' => 'act_s_tracing',
            ],
            tags: ['module' => 'sync'],
        );

        $this->assertNotNull($sentEvent);
        $this->assertCount(1, $testPanel->events());

        $received = $testPanel->events()[0];
        $encoded = json_encode($received, JSON_UNESCAPED_UNICODE);

        // Ningún dato personal debe llegar al panel de Sentry
        $this->assertStringNotContainsString('Mateo González', (string) $encoded);
        $this->assertStringNotContainsString('papa.mateo@ejemplo.com', (string) $encoded);
        $this->assertStringNotContainsString('pixel-9988', (string) $encoded);
        $this->assertStringNotContainsString('192.168.1.45', (string) $encoded);

        // El scrubber los reemplazó por [REDACTED]
        $this->assertStringContainsString('[REDACTED]', $received['message']);
        $this->assertSame('[REDACTED]', $received['extra']['child_name']);
        $this->assertSame('[REDACTED]', $received['extra']['email']);
        $this->assertSame('[REDACTED]', $received['extra']['device_id']);
        $this->assertSame('[REDACTED]', $received['extra']['ip_address']);

        // Metadatos técnicos no personales permanecen intactos para depuración
        $this->assertSame('act_s_tracing', $received['extra']['activity_code']);
        $this->assertArrayNotHasKey('user', $received);
    }

    public function test_errors_are_not_reported_without_privacy_consent(): void
    {
        $testPanel = new InMemoryCrashTransport();
        $reporter = new CrashReporter(transport: $testPanel);

        $result = $reporter->captureException(
            exception: new RuntimeException('Error sin consentimiento de nombre: Sofía Ruiz sofia@correo.com'),
            privacyConsentAccepted: false,
        );

        $this->assertNull($result);
        $this->assertCount(0, $testPanel->events());
    }

    public function test_sentry_http_transport_dispatches_clean_event_in_test_mode(): void
    {
        Http::fake([
            'https://sentry.leoparvulos.test/api/42/store/' => Http::response(['id' => 'evt-clean-001'], 200),
        ]);

        $transport = new SentryHttpTransport('https://pub123key@sentry.leoparvulos.test/42');
        $reporter = new CrashReporter(transport: $transport);

        $reporter->captureException(
            exception: new RuntimeException('Fallo de red para Sofía Martínez (sofia.mama@correo.com)'),
            privacyConsentAccepted: true,
        );

        Http::assertSent(function ($request): bool {
            $body = $request->body();

            return $request->url() === 'https://sentry.leoparvulos.test/api/42/store/'
                && str_contains($request->header('X-Sentry-Auth')[0] ?? '', 'sentry_key=pub123key')
                && str_contains($body, '[REDACTED]')
                && ! str_contains($body, 'Sofía Martínez')
                && ! str_contains($body, 'sofia.mama@correo.com');
        });
    }
}
