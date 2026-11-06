# CC05 - Teclado con prioridad y tono

Matrícula: 20221152 | Correo: 20221152@itla.edu.do | Reto: CC05

## Descripción

`top_module` es un teclado de 4 teclas con prioridad que genera un tono.
Se entrega en Verilog 2001 sintetizable, con un parámetro `K` (por defecto 3).

Interfaz: `clk`, `rst`, `en`, `cmd[7:0]`, `data[7:0]` (no se usa) y `y[15:0]`.

## Arquitectura

- **Codificador de prioridad** (combinacional): convierte `cmd[3:0]` en `key_sel`,
  con 0 = ninguna tecla y 1 a 4 = tecla prioritaria.
- **Registro de estado** (secuencial, un solo `always @(posedge clk)`):
  - `key_q`: tecla activa registrada.
  - `cnt_q`: contador de flancos habilitados.
  - `spk_q`: salida del speaker.
- **Salida:** `y = {12'b0, key_q, spk_q}`, es decir `y[0]` = speaker,
  `y[3:1]` = tecla activa y `y[15:4]` = 0.

La salida depende solo de registros, así que se mantiene estable entre flancos.

## Prioridades y reglas

- La prioridad de teclas es bit0 > bit1 > bit2 > bit3. `cmd[7:4]` se ignora.
- `rst` es síncrono, activo en alto y tiene prioridad sobre todo, incluido `en`.
- Con `en=0` todo el estado se congela, incluida la selección de tecla.
- Con `en=1`:
  - Si la tecla prioritaria cambia respecto a la registrada, se registra la
    nueva, `cnt_q` y `spk_q` pasan a 0 y ese flanco no cuenta para el tono.
  - Si la tecla no cambia y no es 0, `cnt_q` avanza; al completar el periodo
    de `K + activa - 1` flancos, el contador vuelve a 0 y el speaker alterna.
  - Sin teclas, contador y speaker quedan en 0.

## Caso límite

Si la tecla cambia justo en el flanco en el que el speaker iba a alternar, gana
el cambio: el speaker no alterna, se reinicia a 0 y el contador empieza de nuevo
con el periodo de la nueva tecla. Lo cubre `test_change_limit` en `tb_student.v`.

## Cómo correr las pruebas

Requiere Icarus Verilog 12 o posterior.

```bash
iverilog -g2012 -s tb_student -o sim top_module.v tb_student.v
vvp sim
```

Para otro valor de K:

```bash
iverilog -g2012 -s tb_student -Ptb_student.TB_K=5 -o sim top_module.v tb_student.v
vvp sim
```

El testbench imprime `RESULTADO: OK` si no hay errores. También genera
`wave.vcd`, que se puede abrir con GTKWave.

## Pruebas incluidas (`tb_student.v`)

- Reset inicial y ausencia de teclas.
- Cada tecla sola, con su periodo `K + activa - 1`.
- `cmd[7:4]` ignorados y reset con una tecla activa.
- Las 16 máscaras de `cmd[3:0]` contra un modelo de prioridad.
- Cambio de tecla en el límite del periodo.
- Pausa con `en=0`, reset con prioridad sobre `en` y cambios de `cmd` en pausa.
- 900 ciclos pseudoaleatorios contra un modelo de referencia, verificados con
  K=3, 5 y 8.
