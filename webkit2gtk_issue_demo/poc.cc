#include <gtk/gtk.h>
#include <webkit2/webkit2.h>

int main(int argc, char *argv[]) {
    gtk_init(&argc, &argv);

    GtkWidget *window = gtk_window_new(GTK_WINDOW_TOPLEVEL);
    gtk_window_set_title(GTK_WINDOW(window), "Hello World - WebKitGTK");
    gtk_window_set_default_size(GTK_WINDOW(window), 600, 400);

    WebKitWebView *webview = WEBKIT_WEB_VIEW(webkit_web_view_new());
    webkit_web_view_load_html(webview,
                              "<html><body><h1>Hello World!</h1></body></html>",
                              NULL);

    GtkWidget *scroll = gtk_scrolled_window_new(NULL, NULL);
    gtk_container_add(GTK_CONTAINER(scroll), GTK_WIDGET(webview));
    gtk_container_add(GTK_CONTAINER(window), scroll);

    g_signal_connect(window, "destroy", G_CALLBACK(gtk_main_quit), NULL);

    gtk_widget_show_all(window);
    gtk_main();

    return 0;
}

