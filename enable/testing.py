# Copyright (c) 2008-2013 by Enthought, Inc.
# All rights reserved.
from mock import Mock

from enable.abstract_window import AbstractWindow
from enable.events import MouseEvent, KeyEvent

class _MockWindow(AbstractWindow):

    # FIXME: for some reason I cannot replace these functions with a Mock
    def _get_control_size(self):
        return 0, 0

    def _redraw(self, coordinates=None):
        pass


class EnableTestAssistant(object):
    """ Mixin helper for enable/chaco components.

    """

    def press_move_release(self, interactor, points, window=None,
                           alt_down=False, control_down=False,
                           shift_down=False):
        """ Simulate the action of left click pressing, dragging and releasing
        the mouse.

        Parameters
        ----------
        interactor : enable interactor object
            This is object where the mouse events will be dispatched to.

        points : A list of x,y tuple
            The x,y positions of the three event sections. The first tuple
            will be sent with a left-down event and the last will be sent
            with a left-up. All the other events in the list will be sent
            using a mouse-move event.

        window : AbstractWindow, optional
            The enable AbstractWindow to associate with the event. Default
            is to create a mock class instance. If the window has a mouse
            owner then that interactor is used.

        alt_down : boolean, optional
            The button is pressed while `alt` is down. Default value is False.

        control_down : boolean, optional
            The button is pressed while `control` is down. Default value is
            False.

        shift_down : boolean, optional
            The button is pressed while `shift` is down. Default value is
            False.

        """
        x, y = points[0]
        window = self.create_mock_window() if window is None else window
        self.mouse_down(interactor, x, y, 'left', window=window,
                        alt_down=alt_down,
                        control_down=control_down,
                        shift_down=shift_down)
        for x, y in points[1:-1]:
            self.mouse_move(interactor, x, y, window=window,
                            alt_down=alt_down,
                            control_down=control_down,
                            shift_down=shift_down)
        x, y = points[-1]
        self.mouse_up(interactor, x, y, 'left', window=window,
                      alt_down=alt_down,
                      control_down=control_down,
                      shift_down=shift_down)

    def create_mock_window(self):
        """ Creates a Mock class that behaves as an enable Abstract Window.

        Returns
        -------
        window : Mock
            A mock class instance of an abstract window.

        """
        window = _MockWindow()
        window._capture_mouse = Mock()
        window.set_pointer = Mock()
        window._release_mouse = Mock()
        window._redraw = Mock()
        window.control = Mock()
        window.control.set_pointer = Mock()
        return window

    def create_a_mock_gc(self, width, height):
        gc = PlotGraphicsContext((width, height))
        gc.clear((0.0, 0.0, 0.0, 0.0))
        gc.stroke_path = Mock()
        gc.draw_path = Mock()
        return gc

    def create_key_press(self, key, window=None, alt_down=False,
                         control_down=False, shift_down=False):
        """ Creates a KeyEvent for the given Key.

        Parameters
        ----------
        key : string
            The key of the event

        window : AbstractWindow, optional
            The enable AbstractWindow to associate with the event. Default
            is to create a mock class instance.

        alt_down : boolean, optional
            The key is pressed while `alt` is down. Default value is False.

        control_down : boolean, optional
            The key is pressed while `control` is down. Default value is
            False.

        shift_down : boolean, optional
            The key is pressed while `shift` is down. Default value is
            False.

        Returns
        -------
        key_event : KeyEvent
             The enable KEyEvent instance of the desired event ready to be
             passed to an enable Interactor.

        """
        key_event = KeyEvent(character=key,
                             event_type='key_pressed',
                             alt_down=alt_down,
                             control_down=control_down,
                             shift_down=shift_down)
        if window is None:
            key_event.window = self.create_mock_window()
        else:
            key_event.window = window
        return key_event

    def create_mouse_event(self, **kwargs):
        """ Creates a MouseEvent() with the specified attributes.

        """
        # provide defaults for all key shift states
        event_attributes = {
            # key shift states
            'alt_down': False,
            'control_down': False,
            'shift_down': False,
        }
        event_attributes.update(**kwargs)
        event = MouseEvent(**event_attributes)
        return event

    def mouse_down(self, interactor, x, y, button='left', window=None,
                   alt_down=False, control_down=False, shift_down=False):
        """ Send a mouse button down event to the interactor.

        Parameters
        ----------
        interactor : Interactor
            The interactor (or subclass) where to dispatch the event.

        x : float
            The x coordinates of the mouse position

        y : float
            The y coordinates of the mouse position

        button : {'left', 'right'}, optional
            The mouse button for which to simulate a press (down) action.

        window : AbstractWindow, optional
            The enable AbstractWindow to associate with the event. Default
            is to create a mock class instance. If the window has a mouse
            owner then that interactor is used.

        alt_down : boolean, optional
            The button is pressed while `alt` is down. Default value is False.

        control_down : boolean, optional
            The button is pressed while `control` is down. Default value is
            False.

        shift_down : boolean, optional
            The button is pressed while `shift` is down. Default value is
            False.

        Returns
        -------
        event : MouseEvent
            The event instance after it has be processed by the `interactor`.

        """
        window = self.create_mock_window() if window is None else window
        event_attributes = {'x': x, 'y': y,
                            'alt_down': alt_down,
                            'control_down': control_down,
                            'shift_down': shift_down,
                            '{0}_down'.format(button): True,
                            'window': window}
        event = self.create_mouse_event(**event_attributes)
        self._mouse_event_dispatch(interactor, event,
                                   '{0}_down'.format(button))
        return event

    def mouse_move(self, interactor, x, y, window=None,
                   alt_down=False, control_down=False, shift_down=False):
        """ Send a mouse move event to the interactor.

        Parameters
        ----------
        interactor : Interactor
            The interactor (or subclass) where to dispatch the event.

        x : float
            The x coordinates of the mouse position

        y : float
            The y coordinates of the mouse position

        window : AbstractWindow, optional
            The enable AbstractWindow to associate with the event. Default
            is to create a mock class instance. If the window has a mouse
            owner then that interactor is used.

        alt_down : boolean, optional
            The button is pressed while `alt` is down. Default value is False.

        control_down : boolean, optional
            The button is pressed while `control` is down. Default value is
            False.

        shift_down : boolean, optional
            The button is pressed while `shift` is down. Default value is
            False.

        Returns
        -------
        event : MouseEvent
            The event instance after it has be processed by the `interactor`.

        """
        window = self.create_mock_window() if window is None else window
        event = self.create_mouse_event(x=x, y=y,
                                        window=window,
                                        alt_down=alt_down,
                                        control_down=control_down,
                                        shift_down=shift_down)
        self._mouse_event_dispatch(interactor, event, 'mouse_move')
        return event

    def mouse_up(self, interactor, x, y, button='left', window=None,
                 alt_down=False, control_down=False, shift_down=False):
        """ Send a mouse button up event to the interactor.

        Parameters
        ----------
        interactor : Interactor
            The interactor (or subclass) where to dispatch the event.

        x : float
            The x coordinates of the mouse position

        y : float
            The y coordinates of the mouse position

        button : {'left', 'right'}, optional
            The mouse button for which to simulate a release (up) action.

        window : AbstractWindow, optional
            The enable AbstractWindow to associate with the event. Default
            is to create a mock class instance. If the window has a mouse
            owner then that interactor is used.

        alt_down : boolean, optional
            The button is pressed while `alt` is down. Default value is False.

        control_down : boolean, optional
            The button is pressed while `control` is down. Default value is
            False.

        shift_down : boolean, optional
            The button is pressed while `shift` is down. Default value is
            False.

        Returns
        -------
        event : MouseEvent
            The event instance after it has be processed by the `interactor`.

        """
        window = self.create_mock_window() if window is None else window
        event = self.create_mouse_event(x=x, y=y,
                                        window=window,
                                        alt_down=alt_down,
                                        control_down=control_down,
                                        shift_down=shift_down)
        self._mouse_event_dispatch(interactor, event, '{0}_up'.format(button))
        return event

    def mouse_leave(self, interactor, x, y, window=None,
                    alt_down=False, control_down=False, shift_down=False):
        """ Send a mouse click event to the interactor.

        Parameters
        ----------
        interactor : Interactor
            The interactor (or subclass) where to dispatch the event.

        x : float
            The x coordinates of the mouse position

        y : float
            The y coordinates of the mouse position

        window : AbstractWindow, optional
            The enable AbstractWindow to associate with the event. Default
            is to create a mock class instance. If the window has a mouse
            owner then that interactor is used.

        alt_down : boolean, optional
            The button is pressed while `alt` is down. Default value is False.

        control_down : boolean, optional
            The button is pressed while `control` is down. Default value is
            False.

        shift_down : boolean, optional
            The button is pressed while `shift` is down. Default value is
            False.

        Returns
        -------
        event : MouseEvent
            The event instance after it has be processed by the `interactor`.

        """
        window = self.create_mock_window() if window is None else window
        event = self.create_mouse_event(x=x, y=y,
                                        window=window,
                                        alt_down=alt_down,
                                        control_down=control_down,
                                        shift_down=shift_down)
        self._mouse_event_dispatch(interactor, event, 'mouse_leave')
        return event

    def send_key(self, interactor, key, window=None):
        """ Sent a key press event to the interactor.

        Parameters
        ----------
        interactor : Interactor
            The interactor (or subclass) where to dispatch the event.

        key : string
            The key press to simulate.

        window : AbstractWindow, optional
            The enable AbstractWindow to associate with the event. Default
            is to create a mock class instance. If the window has a focus
            owner then that interactor is used.

        Returns
        -------
        event : KeyEvent
            The event instance after it has be processed by the `interactor`.

        """
        window = self.create_mock_window() if window is None else window
        event = self.create_key_press(key, window=window)
        self._key_event_dispatch(interactor, event)
        return event

    def _mouse_event_dispatch(self, interactor, event, suffix):
        mouse_owner = event.window.mouse_owner
        if mouse_owner is None:
            interactor.dispatch(event, suffix)
        else:
            mouse_owner.dispatch(event, suffix)

    def _key_event_dispatch(self, interactor, event):
        focus_owner = event.window.focus_owner
        if focus_owner is None:
            interactor.dispatch(event, 'key_pressed')
        else:
            focus_owner.dispatch(event, 'key_pressed')

    def assertPathsAreProcessed(self, drawable, width=200, height=200):
        """ Check that drawing does not leave paths unused in the GC cache.

        Parameters
        ----------
        drawable :
            A drawable object that has a draw method.

        width : int, optional
            The width of the array buffer

        height : int, optional
            The height of the array buffer

        """
        gc = PlotGraphicsContext((width, height))
        drawable.draw(gc)
        compiled_path = gc._get_path()
        self.assertEqual(
            compiled_path.total_vertices(), 0,
            msg='There are compiled paths that '
            'have not been processed: {0}'.format(compiled_path))

    def assertPathsAreCreated(self, drawable, width=200, height=200):
        """ Check that drawing creates paths.

        Parameters
        ----------
        drawable :
            A drawable object that has a draw method.

        width : int, optional
            The width of the array buffer

        height : int, optional
            The height of the array buffer

        """
        gc = self.create_a_mock_gc(width, height)
        drawable.draw(gc)
        compiled_path = gc._get_path()
        self.assertGreater(
            compiled_path.total_vertices(), 0,
            msg='There are no compiled paths '
            'created: {0}'.format(compiled_path))

    def _mouse_event_dispatch(self, interactor, event, suffix):
        mouse_owner = event.window.mouse_owner
        if mouse_owner is None:
            interactor.dispatch(event, suffix)
        else:
            mouse_owner.dispatch(event, suffix)

    def _key_event_dispatch(self, interactor, event):
        focus_owner = event.window.focus_owner
        if focus_owner is None:
            interactor.dispatch(event, 'key_pressed')
        else:
            focus_owner.dispatch(event, 'key_pressed')
