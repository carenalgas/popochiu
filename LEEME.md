# Popochiu

[![Godot v4.3](https://img.shields.io/badge/Godot-4.3-blue)](https://godotengine.org/download/archive/4.3-stable/) [![Godot v4.2.x](https://img.shields.io/badge/Godot-4.2.x-blue)](https://godotengine.org/download/archive/4.2.2-stable/) [![Discord](https://img.shields.io/discord/1128222869898416182?label=Discord&logo=discord&logoColor=ffffff&labelColor=5865F2&color=5865F2)](https://discord.gg/Frv8C9Ters)

![Imagen de portada](home_banner.png "Popochiu")

Un plugin de Godot para crear juegos point n' click inspirado por [Adventure Game Studio](https://www.adventuregamestudio.co.uk/) y [PowerQuest](https://powerhoof.itch.io/powerquest).

> 🌎👉🏽 [Read the English version](./README.md) 👈🏽🌎

---

🔍 Lee la [Documentación](https://carenalgas.github.io/popochiu/) para saber qué puedes hacer con el plugin.

❤️ Únete al [Discord de Carenalga](https://discord.gg/Frv8C9Ters) para conocer actualizaciones diarias y lanzamientos.

▶️ Sigue los [tutoriales](https://www.youtube.com/playlist?list=PLH0IOYEunrBDz6h4G3vujEmQUZs8vLjz8) (subtítulos en inglés) para aprender a usar el plugin.

## Acerca de

Esta herramienta consta de dos partes: el motor (Popochiu) y el plugin del editor que ayuda con la creación de elementos del juego (nodos y recursos) que utilizan dicho motor. Está inspirado en herramientas bien establecidas para la creación de juegos de aventura gráfica, como Adventure Game Studio y PowerQuest (un plugin para Unity de PowerHoof). Popochiu organiza los juegos en Habitaciones, las escenas donde los Personajes pueden moverse e interactuar con Objetos y Puntos de Interés. También proporciona sistemas de gestión de Inventario y Diálogos.

## Características

### Motor

* Soporte completo para juegos en 2D de estilo retro, pixel art o alta resolución
* Gestión de personajes, con soporte para diferentes emociones durante los diálogos
* Velocidad de texto ajustable y avance automático
* Habitaciones llenas de objetos interactivos, puntos de interés, personajes locales, múltiples áreas transitables, regiones reactivas y marcadores de posición
* Gestión de inventario para tu personaje principal
* Diálogos basados en scripts, que permitien escenas complejas y múltiples interacciones
* Guardado y carga de sesiones de juego
* Gestión del historial de acciones
* Transiciones personalizables entre habitaciones
* Múltiples interfaces gráficas predefinidas con libertad para crear una personalizada
* GUI basada en comandos
* Gestión sencilla de música de fondo y efectos de sonido
* Código y elementos 100% de Godot, sin bloqueos

### Editor

* Panel de Popochiu para acceder fácilmente a todos los elementos del juego
* API moderna e intuitiva basada en GDScript, con funciones de autocompletado
* Creación visual de todos los elementos del juego, con gizmos personalizados para propiedades especiales
* Gestión de árboles de diálogo
* Gestión de audio para música de fondo y efectos de sonido
* Importación de Habitaciones y Personajes, desde archivos fuente de [Aseprite](https://www.aseprite.org/), con toda su estructura

Y vendrán muchas cosas más. Popochiu está en desarrollo activo y tenemos un hoja de ruta de lanzamientos bien mantenida.

## Tabla de compatibilidad

Popochiu es compatible con Godot 4 y Godot 3, pero sólo la versión para Godot 4 está en desarrollo activo, y la versión estable más reciente de Popochiu requiere Godot 4.3.

Por favor, revisa esta tabla para saber qué versión descargar dependiendo de la versión de Godot que quieras usar:

| Versión requerida de Godot | Lanzamiento de Popochiu |
|---|---|
| 4.3 y superior | [Popochiu 2.0](https://github.com/carenalgas/popochiu/releases/download/v2.0/popochiu-v2.0.0.zip) |
| 3.5 a 3.6 | [Popochiu 1.10.1](https://github.com/carenalgas/popochiu/releases/download/v1.10.1/popochiu-v1.10.1.zip) |
| 3.3 a 3.4.5 | [Popochiu 1.8.7](https://github.com/carenalgas/popochiu/releases/download/v1.8.7/popochiu-v1.8.7.zip) |

## Instalación

1. Descarga la versión correcta para tu versión de Godot.
2. Extrae el archivo y copia la carpeta `addons` en la carpeta de tu proyecto.
3. Abre tu proyecto de Godot y habilita el plugin de Popochiu: `Proyecto > Configuración del Proyecto` y selecciona la pestaña `Plugins` en la parte superior.
4. Popochiu te dirá que reiniciará el motor.
5. Verás el panel de Popochiu en el área inferior derecha del editor. ¡Eso es todo!

## Documentación

* Encuentra [aquí la documentación de la última versión](https://carenalgas.github.io/popochiu/).
* Lee [esta wiki para la versión 1.x](https://github.com/carenalgas/popochiu/wiki).

## Tutoriales

Los tutoriales están disponibles para la versión 1.x de Popochiu:

[![tutoriales](https://github.com/carenalgas/popochiu/wiki/images/popochiu_tutorials_button-en.png "Tutorial en Video")](https://www.youtube.com/playlist?list=PLH0IOYEunrBDz6h4G3vujEmQUZs8vLjz8)

Puedes seguir los tutoriales (con subtítulos en inglés) [en esta lista](https://www.youtube.com/playlist?list=PLH0IOYEunrBDz6h4G3vujEmQUZs8vLjz8) para aprender:

* [Instalar el plugin, crear una habitación, un área transitable y un personaje](https://youtu.be/-N62S1DHbcs).
* [Configurar las líneas base, agujeros en áreas transitables y crear Puntos de Interés](https://youtu.be/5RbqbG3_0ak).
* [Crear Objetos interactivos y un objeto de inventario](https://youtu.be/_an0YF3Bd50).
* [Crear diálogos con opciones](https://youtu.be/Aql4wh2itF4).
* [Habilitar opciones dentro de un diálogo y usar objetos de inventario](https://youtu.be/Ad_YBG-_wYE).
* [Agregar otra habitación y configurar la cámara para seguir al personaje](https://youtu.be/YFEZaSty3aw).
* [Agregar audio](https://youtu.be/VF7V6BJmQVQ).

## Hechos con Popochiu

* [Gustavo the Shy Ghost](https://lexibobble.itch.io/gustavo-the-shy-ghost-project) - Inglés.
* [Detective Paws](https://benjatk.itch.io/detective-paws) - Inglés.
* [The Sunnyside Motel in Huttsville Arkansas](https://fgaha56.itch.io/the-sunnyside-motel-in-huttsville-arkansas) - Inglés.
* [Zappin' da Mubis](https://carenalga.itch.io/zappin-da-mubis) - Inglés.
* [Reality-On-The-Norm: Ghost of Reality's Past](https://edmundito.itch.io/ron-ghost) (contraseña: `popochiu`) - Inglés.
* [Breakout (demo)](https://rockyrococo.itch.io/breakout-demo) - Inglés.
* [Poin'n'Sueldo](https://matata-exe.itch.io/pointnsueldo) - Español.
* [Dr. Rajoy](https://guldann.itch.io/dr-rajoy) - Español.
* [I'm Byron Mental](https://leocantus23.itch.io/im-byron-mental-colombia) - Español.
* [Benito Simulator](https://panconqueso94.itch.io/benito-simulator) - Español.
* [Pato & Lobo](https://perroviejo.itch.io/patolobo) - Inglés y Español (este fue el primer juego hecho con Popochiu!).

## Créditos

Popochiu es un proyecto de [Carenalga](https://carenalga.itch.io).
Ahora es mantenido por [Carenalga](https://carenalga.itch.io) y [StickGrinder](https://twitter.com/StickGrinder) con muchas contribuciones de otros miembros de nuestra encantadora comunidad.

:heart::heart::heart: Agradecimientos especiales a :heart::heart::heart:

* [Edmundito](https://github.com/edmundito), [Whyschuck](https://github.com/Whyshchuck), y **Turquoise** por su contribución mensual a nuestro [Ko-fi](https://ko-fi.com/carenalga)
* [Illiterate Code Games](https://illiteratecodegames.itch.io)), [@vonagam](https://github.com/vonagam), [@JuannFerrari](https://github.com/JuannFerrari), [Whyschuck](https://github.com/Whyshchuck) por sus valiosas contribuciones
