# Popochiu

[![Godot v4.6](https://img.shields.io/badge/Godot-4.6-blue)](https://godotengine.org/download/archive/4.6-stable/) [![Discord](https://img.shields.io/discord/1128222869898416182?label=Discord&logo=discord&logoColor=ffffff&labelColor=5865F2&color=5865F2)](https://discord.gg/Frv8C9Ters)

![Imagen de portada](home_banner.png "Popochiu")

Un plugin de Godot para crear aventuras gráficas point-and-click, inspirado en [Adventure Game Studio](https://www.adventuregamestudio.co.uk/) y [PowerQuest](https://powerhoof.itch.io/powerquest).

> 🌎👉🏽 [Read the English version](./README.md) 👈🏽🌎

---

🔍 Lee la [documentación](https://carenalgas.github.io/popochiu/) para descubrir todo lo que puedes hacer con el plugin.

❤️ Únete al [Discord de Carenalga](https://discord.gg/Frv8C9Ters) para estar al día de las novedades y lanzamientos.

## Acerca de

Popochiu consta de dos partes: el motor de ejecución y el plugin del editor. Juntos te ayudan a crear los nodos y recursos necesarios para desarrollar aventuras gráficas clásicas en Godot.

Está inspirado en herramientas consolidadas de creación de aventuras gráficas como Adventure Game Studio y PowerQuest, un plugin de Unity creado por Powerhoof. Popochiu organiza los juegos en Habitaciones, donde los Personajes pueden moverse e interactuar con Objetos y Puntos de Interés, e incluye además sistemas integrados de Inventario y Diálogos.

## Características

### Motor

* Soporte fluido para juegos 2D de estilo retro, pixel art y alta resolución
* Gestión de personajes, incluyendo soporte para distintas emociones durante los diálogos
* Velocidad de texto ajustable y avance automático
* Habitaciones llenas de objetos interactivos, puntos de interés, personajes locales, múltiples áreas transitables, regiones reactivas y marcadores de posición
* Gestión de inventario para tu personaje principal
* Diálogos basados en scripts para escenas complejas e interacciones elaboradas
* Soporte para guardar y cargar partidas
* Gestión del historial de acciones
* Transiciones personalizables entre habitaciones
* Varias interfaces gráficas incluidas de serie, con libertad para crear las tuyas
* Framework de GUI basado en comandos
* Gestión sencilla de música de fondo y efectos de sonido
* Código y recursos 100% Godot, sin dependencias cerradas ni lock-in

### Editor

* Panel de Popochiu para acceder fácilmente a todos los elementos del juego
* API moderna e intuitiva basada en GDScript, con autocompletado
* Creación visual de todos los elementos del juego, con gizmos personalizados para propiedades especiales
* Gestión de árboles de diálogo
* Gestión de audio para música de fondo y efectos de sonido
* Importación de habitaciones, personajes y objetos de inventario desde archivos fuente de [Aseprite](https://www.aseprite.org/), conservando toda su estructura

Y aún queda mucho más por venir. Popochiu está en desarrollo activo y mantenemos una [hoja de ruta pública de lanzamientos](https://github.com/orgs/carenalgas/projects/1/views/1).

## Lanzamientos

La última versión estable pública es **Popochiu 2.1.0**, compatible con **Godot 4.6**.

Usa la tabla siguiente para saber qué versión descargar según tu versión de Godot:

| Versión de Godot requerida | Versión de Popochiu |
| --- | --- |
| 4.6 | [Popochiu 2.1.0](https://github.com/carenalgas/popochiu/releases/tag/v2.1.0) |
| 4.3 | [Popochiu 2.0.3](https://github.com/carenalgas/popochiu/releases/tag/v2.0.3) |

El soporte para Godot 3 está oficialmente discontinuado. Las versiones antiguas siguen disponibles, pero ya no recibirán actualizaciones ni correcciones de errores, por lo que su uso no está recomendado.

## Instalación

1. Descarga la versión correcta para tu versión de Godot.
2. Extrae el archivo y copia la carpeta `addons` dentro de la carpeta de tu proyecto.
3. Abre tu proyecto en Godot y habilita el plugin de Popochiu desde `Proyecto > Configuración del proyecto`, en la pestaña `Plugins`.
4. Popochiu mostrará un aviso indicando que reiniciará el motor.
5. Tras reiniciar el motor, verás el asistente de configuración del juego. Sigue los pasos y elige las opciones que mejor se adapten a tu proyecto.
6. Cuando la configuración termine, verás el panel de Popochiu en la zona inferior derecha del editor. ¡Y ya estaría!

## Primeros pasos

Una vez instalado Popochiu:

1. Ejecuta el asistente de configuración.
2. Crea tu primera habitación.
3. Crea un personaje y colócalo en la habitación.
4. Si es tu primera vez usando el plugin, sigue la [guía para empezar](https://carenalgas.github.io/popochiu/how-to-develop-a-game/introduction/).

## Documentación

* Puedes consultar la documentación de la última versión [aquí](https://carenalgas.github.io/popochiu/).

## Hecho con Popochiu

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
* [Pato & Lobo](https://perroviejo.itch.io/patolobo) - Inglés y español (¡este fue el primer juego hecho con Popochiu!).

## Créditos

Popochiu es un proyecto de [Carenalga](https://carenalga.itch.io).
Actualmente lo mantienen [Carenalga](https://carenalga.itch.io) y [StickGrinder](https://twitter.com/StickGrinder), junto con las numerosas contribuciones de otros miembros de nuestra estupenda comunidad.

:heart::heart::heart: Agradecimientos especiales a :heart::heart::heart:

* [Edmundito](https://github.com/edmundito), [Whyschuck](https://github.com/Whyshchuck) y **Turquoise** por su aportación mensual a nuestro [Ko-fi](https://ko-fi.com/carenalga)
* [Illiterate Code Games](https://illiteratecodegames.itch.io), [@vonagam](https://github.com/vonagam), [@JuannFerrari](https://github.com/JuannFerrari) y [Whyschuck](https://github.com/Whyshchuck) por sus valiosas contribuciones

## Contribuir

Las contribuciones son bienvenidas. Si te apetece colaborar, te recomendamos empezar por la documentación:

* [Contribuir a Popochiu](https://carenalgas.github.io/popochiu/contributing-to-popochiu/)
* [Definition of Done](https://carenalgas.github.io/popochiu/project-management/definition-of-done/)

## Licencia

Este proyecto se distribuye bajo los términos de la [Licencia MIT](LICENSE).
