# ILS Painter

A simple flutter widget to paint with your fingers.

## Features

The widget supports:
- Changing fore- and background color
- Changing the thickness of lines you draw
- Exporting your painting as png
- Undo drawing a line
- Redo drawing a line
- Clearing the hole drawing

## Some Notes

- After calling 'finish()' on a PainterController you can't draw on this painting any more
- To create a new painting after finishing the old one simply create a new PainterController
- Calling 'finish()' for the first time will render the drawing. Successive calls will then return a cached version of the rendered picture 

## Example

```arb
class ExamplePage extends StatefulWidget {
   @override
   _ExamplePageState createState() => _ExamplePageState();
}

class _ExamplePageState extends State<ExamplePage> {
  bool _finished = false;
  PainterController _controller = _newController();

  @override
  void initState() {
    super.initState();
  }

  static PainterController _newController({String history = ''}) {
    PainterController controller =
        PainterController(history: history, compressionLevel: 4,);
    controller.thickness = 5.0;
    controller.backgroundColor = Colors.green;
    return controller;
  }

  String history = '';

  @override
  Widget build(BuildContext context) {
return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: AspectRatio(aspectRatio: 1.0, child: Painter(_controller)),
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            child: const Icon(Icons.undo),
            onPressed: () {
              setState(() {
                _controller.undo();
              });
            },
          ),
          FloatingActionButton(
            child: const Icon(Icons.redo),
            onPressed: () {
              setState(() {
                _controller.redo();
              });
            },
          ),
          FloatingActionButton(
            child: const Icon(Icons.restore),
            onPressed: () {
              setState(() {
                _controller = _newController(history: history);
              });
            },
          ),
          FloatingActionButton(
            child: const Icon(Icons.delete),
            onPressed: () {
              setState(() {
                history = _controller.history;
                _controller.clear();
              });
            },
          ),
          FloatingActionButton(
            child: const Icon(Icons.navigate_next),
            onPressed: () {
           
            },
          ),
        ],
      ),
    );
    }

```

![demo!](https://github.com/iLeafSolutionsPvtLtd/ILSPainter/example/demo.gif)