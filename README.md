# CC05 - Teclado con prioridad y tono
Matricula: 20221152 | Correo: 20221152@itla.edu.do | Reto: CC05

## Plan
1. Codificador de prioridad sobre cmd[3:0] (bit0 > bit1 > bit2 > bit3).
2. Deteccion de cambio: key_sel contra key_q (registrada).
3. Contador y speaker: alterna cada K+activa-1 flancos con en=1.
4. Casos: reset prioritario, en=0 congela todo, sin teclas -> cnt=0 y spk=0.

## Estado
Commit 1: interfaz y estructura.
