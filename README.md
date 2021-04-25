# Godot Adventure Quest
Framework para crear juegos de aventura con Godot al estilo de [Adventure Game Studio](https://www.adventuregamestudio.co.uk/) y [Power Quest](https://powerhoof.itch.io/powerquest).

![cover](./assets/images/_repo/cover.png "Godot Adventure Quest")


# Resumen 📃

El framework tiene unos script cargados en el Autoload para facilitar el acceso a funciones de uso global: CharacterInterface, Inventory, GraphicInterfaceEvents, Cursor, Utils, Data.

* C (para acceder a CharacterInterface.gd)
  ```gdscript
  # El personaje controlado por el jugador dice Hola
  C.player.say('Hola')
  # Un personaje llamado Barney se pone grosero
  C.character_say('Barney', '¡Cállese maricón!')
  # El personaje controlado por el jugador se pone grosero también
  C.player_say('Qué malparido tan grosero')
  ```
* G (para acceder a GraphicInterfadeEvents.gd)
  ```gdscript
  # Muestra un mensaje centrado, como una notificación.
  G.display('Usa clic izquierdo para interactuar y clic derecho para examinar')
  # En la parte inferior de la pantalla se puede ver el nombre del objeto sobre el que está el cursor
  G.show_info('Llave')
  ```
* I (para acceder a Inventory.gd)
  ```gdscript
  # Añade el ítem Bucket al inventario
  I.add_item('Bucket')
  # Añade el ítem Bucket al inventario y lo hace, automáticamente, el ítem activo
  I.add_item_as_active('Bucket')
  ```
* ???

# Configuración ⚙
- [ ] Que sea fácil indicarle al framework que el juego tiene controles de movimiento 2D (como casi todos los point n' click) o 1D (como [Short-term Battery](https://gamejolt.com/games/short-term-battery/340825) o [Loco Motive](https://robustgames.itch.io/loco-motive) o [iD](https://gamejolt.com/games/iD/256559)).

# Controles 🎮
* Clic para interactuar con los objetos y personajes, para hacer mover al personaje jugable y para hace cualquier acción de inventario o menú. Si hay un ítem del inventario activo, esta acción hace que se use sobre el objeto o el personaje que esté bajo el cursor.
* Clic derecho para examinar los objetos y personajes. Si hay un ítem del inventario activo, esta acción lo desactiva. Se pueden examinar objetos del inventario.

---

# Objetos 📦
> _Sí... esto debería ir en la documentación, pero... soy sólo un hombre... y... "What is a man!?"_ 🧛‍♂️

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

- [ ] Que haya algo que haga entender que se puede hacer clic para avanzar en el diálogo o saltar pasos de una escena cinemática (cutscene).
- [ ] 

### Texto de descripción (InfoBar.tscn + InfoBar.gd)
- [ ] Mover el elemento a una escena con su script propio.
- [x] Que se pueda mostrar un texto de descripción cuando el cursor pasa sobre un objeto.

### Texto de diálogo (DialogText.tscn + DialogText.gd)
- [ ] Calcular la altura del texto para que no se supoerponga al personaje que habla.
- [ ] Que al renderizarse en el borde el texto no se alinee al centro. Si se sale por la izquierda, alinearlo a la izquierda, si se sale por la derecha alinearlo a la derecha.
- [x] Renombrar AnimatedRichText por DialogText.
- [x] Que nodo no se salga de la pantalla en los bordes. Si se sale por la izquierda, debería renderizarse a 4px del borde; igual para el borde derecho.
- [x] Que nodo tenga un ancho máximo y uno mínimo para controlar el Autowrap.
- [x] Actualizar Label por el AnimatedRichText creado para [Kaloche](https://quietgecko.itch.io/kaloche).
- [x] Que texto aparezca sobre el personaje que habla.
- [x] Que se pueda mostrar un texto dicho por un personaje.

### Texto de aviso (DisplayBox.tscn + DisplayBox.gd)
- [ ] Que tenga un ancho máximo definido para que empiece a hacer Autowrap.
- [ ] Que vuelva a su tamaño original antes de mostrar el texto recibido.
- [x] Que se pueda mostrar un texto de aviso.

### Menú de opciones de diálogo (DialogMenu.tscn + DialogMenu.gd + DialogOption.tscn)
- [x] Mover el DialogMenu a una escena independiente.
- [x] Que al seleccionar una opción se cierre el menú de opciones de diálogo y se envíe la opción seleccionada como parámetro de una señal.
- [x] Que haya un VBoxContainer para mostrar las opciones del diálogo.

## Inventory (Inventory.gd)
- [x] Que se puedan eliminar ítems del inventario.
- [x] Que se puedan usar ítems del inventario.
- [x] Que se pueda agregar un ítem al inventario y que de una vez se convierta en el ítem activo.
- [x] Que se pueda "soltar" el ítem activo cuando se hace clic derecho al tener un objeto de inventario activo.
- [x] Que se pueda agregar un ítem (Item.gd) al inventario.

## Diálogos (Dialog.gd)
- [x] Que al seleccionar una opción del menú de diálogo este se cierre y se pase la opción seleccionada como parámetro de la señal que permite al juego continuar con el flujo de instrucciones.
- [x] Que se puede disparar un inline-dialog pasando las opciones como un arreglo de `String`.