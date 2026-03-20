Hola soy Carlos Nava Rodríguez estudiante de Ingeniería en Computación en la UDG, soy  de 9no Semestre, este proyecto fue desarrollado para la materia de Programación de Gráficos 3D impartida por el profesor José Luis David Bonilla Carranza, nos estamos adentrando al desarrollo de videojuegos 2D para conocer el Motor de Godot 4.6, este es el segundo proyecto desarrollado.

"Dawn of Victory" es un simulador de duelos por turnos desarrollado en Godot Engine 4.6, inspirado en las mecánicas clásicas de los RPG de GameBoy como Pokémon. El proyecto implementa un bucle de combate completo, gestión de estados alterados, inventario estratégico y una cinemática final dinámica.

Itchio: https://karlosdev.itch.io/dawn-of-victory

El juego utiliza una máquina de estados lógica gestionada por código para controlar el flujo de la batalla:

Turno del Jugador: El usuario puede elegir entre atacar, usar objetos de la mochila o intentar huir.

Sistema de Combate: 

Ataque Rápido: Daño moderado y seguro.
Ataque Potente: Gran daño pero con un 20% de probabilidad de fallo.
Golpes Críticos: 15% de probabilidad de infligir daño extra (x1.5) en el siguiente ataque.
Mochila de Ítems (Estratégica):

Poción de Vida: Recupera 50 HP.
Poción de Fuerza: Multiplica el daño del siguiente ataque por 1.5.
Inmunidad: Protege contra estados alterados durante 3 turnos.
Agilidad: Aumenta la probabilidad de esquiva al 40%.
Sistema de Huida: Permite escapar del combate (50% éxito base), con un cooldown de 3 turnos tras un intento fallido.

Enemigo	HP	Habilidad Especial	Estado Alterado
Golem	200	Gran resistencia	Dormido: El jugador pierde turnos aleatorios.
Dragón	80	Alto daño	Quemado: Daño constante (5 HP) por turno.
Demonio	150	Equilibrado	Confundido: 40% de probabilidad de golpearte a ti mismo.
El juego termina tras derrotar a 5 enemigos.

Creditos:

Desarrollador: Carlos Nava Rodríguez

Musica:

 https://pixabay.com/es/
https://opengameart.org/
https://www.beepbox.co/#9n31s0k0l00e03t2ma7g0fj07r1i0o432T1v1uecf12ldq00d4aAcF8B8Q0001PffffE17aT7v1u71f50p61770q72d42g3q0F21a90k762d06HT-SRJJJJIAAAAAh0IaE1c11T5v1ua4f62ge2ec2f02j01960meq8141d36HT-Iqijriiiih99h0E0T2v1u15f10w4qw02d03w0E0b4h400000000h4g000000014h000000004h400000000p16000000
Sprites2D: Generados por IA Gemini usando NanoBanana 2

Motor utilizado: Godot Engine 4.6 

Lenguaje de Programación: DGScript 
