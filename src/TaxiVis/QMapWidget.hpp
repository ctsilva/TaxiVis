#ifndef Q_MAP_WIDGET_HPP
#define Q_MAP_WIDGET_HPP

#include <GL/glew.h>
#include <QGraphicsView>
#include <QSlider>
#include <QGraphicsProxyWidget>
#include <QOpenGLWidget>
#include <vector>

class QMapTileWidget;
class RenderingLayer;

class QMapWidget : public QGraphicsView
{
  Q_OBJECT
public:
  QMapWidget(QWidget *parent=0);
  QMapWidget(QPointF coords, int level=15, QWidget *parent=0);
  virtual ~QMapWidget() {}

  QMapTileWidget *mapView() { return this->mView; }
  void repaintContents();

  virtual void loadFinished() {}
  virtual void initGL() {}
  virtual void paintOverlay(QPainter */*painter*/) {}

protected:
  void initWidget(QPointF coords, int level);
  void resizeEvent(QResizeEvent *event);
  void closeEvent(QCloseEvent *event);

private:
  QMapTileWidget *mView;
};

#endif
