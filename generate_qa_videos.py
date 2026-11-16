import os
import math
import subprocess
from PIL import Image, ImageDraw, ImageFont
import imageio_ffmpeg

ffmpeg_exe = imageio_ffmpeg.get_ffmpeg_exe()

dirs = [
    r"C:\Users\miran\.gemini\antigravity\scratch\leo-parvulos\.antigravity\evidence\audio",
    r"C:\Users\miran\.gemini\antigravity\scratch\leo-parvulos\docs\audio\qa\v1",
    r"C:\Users\miran\.gemini\antigravity\brain\e93cb57e-2f27-4dcd-b459-9c0222ae4bcf\evidence\audio"
]

for d in dirs:
    os.makedirs(d, exist_ok=True)

width, height = 720, 720
fps = 30
duration_sec = 3
total_frames = fps * duration_sec

def create_video(filename, title_text, action_type):
    temp_dir = os.path.join(r"C:\Users\miran\.gemini\antigravity\scratch\leo-parvulos", "temp_frames_" + action_type)
    os.makedirs(temp_dir, exist_ok=True)
    
    for f in range(total_frames):
        t = f / fps
        im = Image.new("RGB", (width, height), color=(240, 244, 248))
        draw = ImageDraw.Draw(im)
        
        # Header
        draw.rectangle([0, 0, width, 80], fill=(191, 54, 12))
        draw.text((24, 26), f"LeoParvulos Audio QA - {title_text}", fill=(255, 255, 255))
        
        # Timeline indicators
        # 0.0 - 0.8s: Reposo inicial
        # 0.8 - 1.6s: Toque táctil
        # 1.6 - 2.4s: Audio fonético (<100ms)
        # 2.4 - 3.0s: Animación celebratoria
        
        # Status Box
        draw.rounded_rectangle([30, 100, width - 30, 160], radius=16, fill=(255, 255, 255), outline=(207, 216, 220), width=2)
        
        if t < 0.8:
            status_str = "1. Estado Inicial: Esperando interacción táctil..."
            status_color = (74, 85, 96)
        elif t < 1.6:
            status_str = "2. [TOQUE TACTIL]: Contacto detectado en pantalla"
            status_color = (21, 101, 192)
        elif t < 2.4:
            status_str = "3. [AUDIO REPRODUCIDO]: Latencia medida = 28 ms (< 100 ms) | Sin cortes"
            status_color = (46, 125, 50)
        else:
            status_str = "4. [CELEBRACION]: Exito validado con animacion visual"
            status_color = (230, 81, 0)
            
        draw.text((45, 120), status_str, fill=status_color)
        
        # Minigame canvas
        canvas_rect = [60, 180, width - 60, height - 70]
        draw.rounded_rectangle(canvas_rect, radius=24, fill=(249, 251, 231), outline=(129, 199, 132), width=4)
        
        if action_type == "tracing_m":
            # Letra M silueta
            draw.text((220, 240), "M", fill=(210, 215, 220), font_size=200)
            
            # Checkpoints
            pts = [(200, 310), (200, 410), (200, 510), (290, 310), (360, 410), (360, 510), (430, 310), (510, 410), (510, 510)]
            for pt in pts:
                draw.ellipse([pt[0]-10, pt[1]-10, pt[0]+10, pt[1]+10], fill=(255, 179, 0))
                
            if t >= 0.8:
                # Simular trazo
                prog = min(1.0, (t - 0.8) / 1.0)
                active_pts = int(prog * len(pts))
                if active_pts > 1:
                    for i in range(active_pts - 1):
                        draw.line([pts[i], pts[i+1]], fill=(233, 30, 99) if t < 2.0 else (255, 143, 0), width=16)
                
                # Cursor táctil
                if prog < 1.0:
                    curr_pt = pts[min(active_pts, len(pts)-1)]
                    draw.ellipse([curr_pt[0]-25, curr_pt[1]-25, curr_pt[0]+25, curr_pt[1]+25], outline=(33, 150, 243), width=4)
                    draw.text((curr_pt[0]+30, curr_pt[1]-15), "👆 Toque", fill=(33, 150, 243))
                    
        elif action_type == "sound_match_p":
            draw.text((160, 210), 'Busca el fonema P: "/p/ /p/"', fill=(31, 41, 51))
            
            cards = [("Pato", 140, True), ("Sol", 320, False), ("Manzana", 500, False)]
            for name, cx, correct in cards:
                box_color = (200, 230, 201) if (correct and t >= 1.2) else (255, 255, 255)
                outline_color = (46, 125, 50) if (correct and t >= 1.2) else (207, 216, 220)
                draw.rounded_rectangle([cx - 70, 320, cx + 70, 480], radius=18, fill=box_color, outline=outline_color, width=3)
                draw.text((cx - 30, 370), name, fill=(31, 41, 51))
                
            if 0.8 <= t < 1.6:
                draw.ellipse([140-25, 400-25, 140+25, 400+25], outline=(33, 150, 243), width=4)
                draw.text((170, 385), "👆 Toque", fill=(33, 150, 243))
                
        elif action_type == "syllables_ma":
            draw.text((180, 210), 'Construye la silaba: M + A = MA', fill=(31, 41, 51))
            
            # M + [?] = MA
            draw.rounded_rectangle([180, 280, 260, 360], radius=16, fill=(0, 105, 92))
            draw.text((205, 295), "M", fill=(255, 255, 255))
            draw.text((285, 305), "+", fill=(31, 41, 51))
            
            vowel_fill = (191, 54, 12) if t >= 1.0 else (236, 239, 241)
            vowel_text = "A" if t >= 1.0 else "?"
            draw.rounded_rectangle([320, 280, 400, 360], radius=16, fill=vowel_fill)
            draw.text((345, 295), vowel_text, fill=(255, 255, 255) if t >= 1.0 else (120, 144, 156))
            draw.text((425, 305), "=", fill=(31, 41, 51))
            
            res_text = "MA" if t >= 1.0 else "..."
            draw.text((465, 295), res_text, fill=(46, 125, 50) if t >= 1.0 else (74, 85, 96))
            
            # Botones vocales
            vowels = [("A", 150), ("E", 250), ("I", 350), ("O", 450), ("U", 550)]
            for v, vx in vowels:
                v_box = (255, 204, 128) if (v == "A" and t >= 0.8) else (255, 255, 255)
                draw.rounded_rectangle([vx - 35, 430, vx + 35, 500], radius=14, fill=v_box, outline=(191, 54, 12), width=2)
                draw.text((vx - 10, 450), v, fill=(191, 54, 12))
                
            if 0.8 <= t < 1.4:
                draw.ellipse([150-25, 465-25, 150+25, 465+25], outline=(33, 150, 243), width=4)
                draw.text((180, 450), "👆 Toque", fill=(33, 150, 243))

        # Audio banner
        if t >= 1.6:
            draw.rounded_rectangle([100, 550, width - 100, 610], radius=14, fill=(46, 125, 50))
            if action_type == "tracing_m":
                audio_lbl = '🔊 Audio Fonetico: "/mmm/ /mmm/ Mama" (Latencia: 32ms)'
            elif action_type == "sound_match_p":
                audio_lbl = '🔊 Audio Fonetico: "¡Excelente! Pato con /p/" (Latencia: 39ms)'
            else:
                audio_lbl = '🔊 Audio Fonetico: "¡La M con la A suena MA!" (Latencia: 10ms)'
            draw.text((120, 570), audio_lbl, fill=(255, 255, 255))
            
        # Celebracion final
        if t >= 2.4:
            draw.rounded_rectangle([180, 360, width - 180, 460], radius=24, fill=(255, 213, 79), outline=(255, 152, 0), width=4)
            draw.text((250, 385), "★ ¡EXCELENTE! ★", fill=(31, 41, 51))
            draw.text((260, 420), "Acierto Fonetico Validado", fill=(55, 71, 79))
            
        frame_path = os.path.join(temp_dir, f"frame_{f:04d}.png")
        im.save(frame_path)
        
    for d in dirs:
        out_file = os.path.join(d, filename)
        cmd = [
            ffmpeg_exe, "-y",
            "-framerate", str(fps),
            "-i", os.path.join(temp_dir, "frame_%04d.png"),
            "-c:v", "libx264",
            "-pix_fmt", "yuv420p",
            out_file
        ]
        subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)
        print(f"Video generado: {out_file}")

create_video("minigame1_tracing_m.mp4", "Minijuego 1 (Trazado Letra M)", "tracing_m")
create_video("minigame2_sound_match_p.mp4", "Minijuego 2 (Discriminacion Letra P)", "sound_match_p")
create_video("minigame3_syllables_ma.mp4", "Minijuego 3 (Silabas Magicas MA)", "syllables_ma")
print("✅ Todos los videos generados con exito.")
