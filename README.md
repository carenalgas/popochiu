# godot_adventure_quest
Framework para crear juegos de aventura con Godot al estilo de [Adventure Game Studio](https://www.adventuregamestudio.co.uk/) y [Power Quest](https://powerhoof.itch.io/powerquest).

![cover](./assets/images/_repo/cover.png "Godot Adventure Quest")


# Resumen

El framework tiene unos script cargados en el Autoload para facilitar el acceso a funciones de uso global: CharacterInterface, Inventory, GraphicInterfaceEvents, Cursor, Utils, Data.

* C (para acceder a CharacterInterface.gd)
  ```gdscript
  C.player.say('Hola')
  C.character_say('Barney', '¡Cállese maricón!')
  C.player_say('Qué malparido tan grosero')
  ```
* G (para acceder a GraphicInterfadeEvents.gd)
  ```
  G.display('Usa clic izquierdo para interactuar, y clic derecho para examinar')
  ```
* I (para acceder a Inventory.gd)
  ```
  I.add_item('Bucket')
  ```
* ???


# Objetos

## Personajes (Character.tscn + Character.gd)
_Cualquier objeto que pueda hablar, caminar, moverse entre habitaciones, tener inventario, entre otras muchas cosas._

- [ ] Que la función caminar tenga una corrutina y no el CharacterInterface.gd.
- [ ] Que personaje pueda mirar en la dirección del objeto al que se hizo clic.
- [ ] Que personaje pueda mirar en la dirección de un objeto específico (puede ser un personaje, un hotspot, un prop, etcétera).

## Clickable
_Nodo del que heredan todos aquellos objetos que vayan a tener interacción con clic izquierdo o derecho._
- [x] Crear Clickable.gd para que Character, Hotspot y Prop hereden de este.

## Interfaz gráfica (GraphicInterface.tscn + GraphicInterface.gd)
_Controla lo elementos de la Interfaz Gráfica del Jugador (IGJ): mostrar textos de diálogo (DialogText), textos de aviso, o narrador, (DisplayBox), el inventario (InventoryContainer), el menú de opciones (Toolbar), el menú de diálogo (DialogMenu) y los textos de descripción (InfoBar), entre otros._

### Texto de descripción (InfoBar)
- [ ] Mover el elemento a una escena con su script propio.
- [x] Que se pueda mostrar un texto de descripción cuando el cursor pasa sobre un objeto.

### Texto de diálogo (DialogText)
- [ ] Calcular la altura del texto para que no se supoerponga al personaje que habla.
- [x] Que texto aparezca sobre el personaje que habla.
- [x] Que se pueda mostrar un texto dicho por un personaje.

### Texto de aviso (DisplayBox)
- [ ] Que tenga un ancho máximo definido para que empiece a hacer Autowrap.
- [ ] Que vuelva a su tamaño original antes de mostrar el texto recibido.
- [x] Que se pueda mostrar un texto de aviso.

## Diálogos (Dialog.gd)
- [x] Que al seleccionar una opción del menú de diálogo este se cierre y se pase la opción seleccionada como parámetro de la señal que permite al juego continuar con el flujo de instrucciones.
- [x] Que se puede disparar un inline-dialog pasando las opciones como un arreglo de `String`.