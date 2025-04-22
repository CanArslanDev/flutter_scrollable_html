# Flutter Scrollable HTML



https://github.com/user-attachments/assets/6437d644-aaf1-4607-9a94-d55df39b8a80


This project provides an advanced integration solution that allows seamless rendering of HTML content and interactive behavior within a Flutter Web application.

## 🌟 Features

- Render HTML content within the Flutter Web app with a native-like experience
- Bidirectional interaction (Flutter ↔ HTML)
- Text selection and copy support
- Keyboard and mouse event support
- Responsive design support

## 🏗 Project Structure
```
lib/
├── features/
│ └── main/
│ ├── presentation/
│ │ ├── pages/
│ │ │ └── main_page.dart # Main page
│ │ ├── widgets/
│ │ │ ├── html_view_section.dart # HTML view section
│ │ │ └── flutter_native_section.dart # Flutter native section
│ │ └── controllers/
│ │ └── main_page_controller.dart # Page controller
│ └── utils/
│ ├── iframe_handler.dart # iframe management
│ └── event_handlers.dart # Event handlers
```
## 🛠 Technical Details

### HTML Integration
The project renders HTML content within the Flutter Web application via an iframe. This iframe is integrated into the Flutter app using the `HtmlElementView` widget.

### Event Handling
The project manages three main types of events:
1. **Mouse Events**: Click, drag, hover, and other mouse events
2. **Keyboard Events**: Keyboard input
3. **Selection Events**: Text selection events

### Cursor Management
The system automatically detects cursor styles for HTML elements and applies the appropriate cursor style on the Flutter side:
- Pointer cursor for clickable elements
- Text cursor for text areas
- Grab/grabbing cursor for draggable elements

### Communication Mechanism
The communication between Flutter and HTML is done using the postMessage API:
- Flutter → HTML: JavaScript code is injected
- HTML → Flutter: MessageEvent listeners are used

## 🚀 How It Works?

1. **Initialization**
   - IframeHandler loads the HTML content
   - Event listeners are set up
   - Cursor tracking begins

2. **Event Flow**
User Input → Flutter Event → HTML Event Simulation → HTML Response → Flutter Update

3. **State Management**
- Each component manages its own state
- MainPageController handles central coordination

## 💡 Usage

```dart
void main() {
  runApp(MaterialApp(
    home: MainPage(),
  ));
}
```

Place your HTML content in the `web/assets/index.html` file:

```html
<!DOCTYPE html>
<html>
<head>
    <style>
        /* Your custom styles */
    </style>
</head>
<body>
    <!-- Your HTML content -->
</body>
</html>
```

## 🔧 Development Notes
### Best Practices
- Optimize event handlers
- Avoid unnecessary re-renders
- Don't forget to dispose to prevent memory leaks

### Performance Tips
- Avoid heavy DOM manipulations
- Use event throttling
- Use RAF (RequestAnimationFrame)

### Security Notes
- Load HTML content from trusted sources
- Apply XSS protection
- Be mindful of CORS policies

## 🐛 Known Issues and Solutions
### Scroll Synchronization
**Problem:** Nested scroll conflicts
**Solution:** Use PointerInterceptor widget

### Focus Management
**Problem:** Focus state confusion
**Solution:** Use FocusNode and manual focus management

### Event Bubbling
**Problem:** Duplicate events
**Solution:** Apply event stopPropagation

## 🤝 Contributing
- Fork the project
- Create your feature branch
- Commit your changes
- Push to the branch
- Create a Pull Request

## 📝 License
This project is licensed under the MIT License.
