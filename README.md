1. Home Page:


✅ Displays a summary of cartridges and their slots (home_screen.dart)


✅ Users can control and view the current state of cartridges


✅ Allows updating the order of cartridges in slots (via drag-and-drop)


✅ Enables updating the inventory level of each slot


2. Carousel Page:


✅ Provides a detailed view of cartridges in carousel slots (carousel_screen.dart)


✅ Displays cartridges in their assigned slots, highlighting:


✅ Empty slots (shown with DashedCirclePainter)


✅ Duplicated cartridges (multiple instances of the same cartridge in different slots)


✅ Change-now cartridges (when quantity is below 30g)


3. Technical Preferences:


✅ State Management: Uses Bloc pattern (cartridge_bloc.dart, cartridge_event.dart, cartridge_state.dart)


✅ Local Database: Integration with SQLite to persist cartridge data and maintain an offline-first approach


4. Bonus Features:


✅ Basic error handling for slot assignments (preventing more than one cartridge in the same slot)


✅ Feature to reset slot order to default state (Reset Slots button)


✅ API Integration:


✅ Integration with remote API to fetch cartridge data periodically and synchronize local data


✅ Pull-to-refresh mechanism on the Home Page to fetch latest data from the API

