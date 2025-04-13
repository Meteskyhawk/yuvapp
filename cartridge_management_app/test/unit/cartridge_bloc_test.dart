import 'package:bloc_test/bloc_test.dart';
import 'package:cartridge_management_app/data/models/cartridge_model.dart';
import 'package:cartridge_management_app/data/repositories/cartridge_repository.dart';
import 'package:cartridge_management_app/logic/blocs/cartridge/cartridge_bloc.dart';
import 'package:cartridge_management_app/logic/blocs/cartridge/cartridge_event.dart';
import 'package:cartridge_management_app/logic/blocs/cartridge/cartridge_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'cartridge_bloc_test.mocks.dart';

@GenerateMocks([CartridgeRepository])
void main() {
  group('CartridgeBloc', () {
    late MockCartridgeRepository mockRepository;
    late CartridgeBloc cartridgeBloc;

    final testCartridge = CartridgeModel(
      id: 'test-id-1',
      colorCode: 'BLU',
      quantity: 100,
      slot: 1,
    );

    final updatedCartridge = testCartridge.copyWith(quantity: 75);

    final cartridges = [
      testCartridge,
      CartridgeModel(
        id: 'test-id-2',
        colorCode: 'RED',
        quantity: 200,
        slot: 2,
      ),
    ];

    setUp(() {
      mockRepository = MockCartridgeRepository();
      cartridgeBloc = CartridgeBloc(repository: mockRepository);
    });

    tearDown(() {
      cartridgeBloc.close();
    });

    test('initial state should be CartridgeInitial', () {
      expect(cartridgeBloc.state, isA<CartridgeInitial>());
    });

    blocTest<CartridgeBloc, CartridgeState>(
      'emits [CartridgeLoading, CartridgeLoaded] when LoadCartridges is added',
      build: () {
        when(mockRepository.getAllCartridges())
            .thenAnswer((_) async => cartridges);
        return cartridgeBloc;
      },
      act: (bloc) => bloc.add(LoadCartridges()),
      expect: () => [
        isA<CartridgeLoading>(),
        isA<CartridgeLoaded>().having(
          (state) => (state as CartridgeLoaded).cartridges,
          'cartridges',
          cartridges,
        ),
      ],
      verify: (_) {
        verify(mockRepository.getAllCartridges()).called(1);
      },
    );

    blocTest<CartridgeBloc, CartridgeState>(
      'emits [CartridgeLoading, CartridgeLoaded] when AddCartridge is added',
      build: () {
        when(mockRepository.isSlotOccupied(any)).thenAnswer((_) async => false);
        when(mockRepository.insertCartridge(any)).thenAnswer((_) async => {});
        when(mockRepository.getAllCartridges())
            .thenAnswer((_) async => [...cartridges, testCartridge]);
        return cartridgeBloc;
      },
      act: (bloc) => bloc.add(AddCartridge(testCartridge)),
      expect: () => [
        isA<CartridgeLoading>(),
        isA<CartridgeLoaded>(),
      ],
      verify: (_) {
        verify(mockRepository.isSlotOccupied(testCartridge.slot)).called(1);
        verify(mockRepository.insertCartridge(testCartridge)).called(1);
        verify(mockRepository.getAllCartridges()).called(1);
      },
    );

    blocTest<CartridgeBloc, CartridgeState>(
      'emits [CartridgeLoading, CartridgeLoaded] when UpdateCartridge is added',
      build: () {
        when(mockRepository.updateCartridge(updatedCartridge))
            .thenAnswer((_) async => {});
        when(mockRepository.getAllCartridges())
            .thenAnswer((_) async => [updatedCartridge]);
        return cartridgeBloc;
      },
      act: (bloc) => bloc.add(UpdateCartridge(updatedCartridge)),
      expect: () => [
        isA<CartridgeLoading>(),
        isA<CartridgeLoaded>().having(
          (state) => (state as CartridgeLoaded).cartridges,
          'cartridges',
          [updatedCartridge],
        ),
      ],
      verify: (_) {
        verify(mockRepository.updateCartridge(updatedCartridge)).called(1);
        verify(mockRepository.getAllCartridges()).called(1);
      },
    );

    blocTest<CartridgeBloc, CartridgeState>(
      'emits [CartridgeLoading, CartridgeLoaded] when DeleteCartridge is added',
      build: () {
        when(mockRepository.deleteCartridge(testCartridge.id))
            .thenAnswer((_) async => {});
        when(mockRepository.getAllCartridges()).thenAnswer((_) async => []);
        return cartridgeBloc;
      },
      act: (bloc) => bloc.add(DeleteCartridge(testCartridge.id)),
      expect: () => [
        isA<CartridgeLoading>(),
        isA<CartridgeLoaded>().having(
          (state) => (state as CartridgeLoaded).cartridges,
          'cartridges',
          [],
        ),
      ],
      verify: (_) {
        verify(mockRepository.deleteCartridge(testCartridge.id)).called(1);
        verify(mockRepository.getAllCartridges()).called(1);
      },
    );

    blocTest<CartridgeBloc, CartridgeState>(
      'emits [CartridgeLoading, CartridgeError] when repository throws',
      build: () {
        when(mockRepository.getAllCartridges())
            .thenThrow(Exception('Database error'));
        return cartridgeBloc;
      },
      act: (bloc) => bloc.add(LoadCartridges()),
      expect: () => [
        isA<CartridgeLoading>(),
        isA<CartridgeError>().having(
          (state) => (state as CartridgeError).message,
          'error message',
          contains('Database error'),
        ),
      ],
    );
  });
}
