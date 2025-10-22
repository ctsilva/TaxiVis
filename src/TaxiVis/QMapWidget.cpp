#include "QMapWidget.hpp"
#include "QMapTileWidget.hpp"
#include <QTimer>
#include <QScrollBar>
#include <QGraphicsScene>
#include <QSlider>
#include <QApplication>
#include <QOpenGLWidget>
#include <QSurfaceFormat>
#include <stdio.h>
#include <math.h>

QMapWidget::QMapWidget(QWidget *parent)
    : QGraphicsView(parent)
{
  this->initWidget(QPointF(40.7566, -73.9863), 15);
}

QMapWidget::QMapWidget(QPointF coords, int level, QWidget *parent)
    : QGraphicsView(parent)
{
  this->initWidget(coords, level);
}

void QMapWidget::initWidget(QPointF coords, int level)
{
  QSurfaceFormat fmt = QSurfaceFormat::defaultFormat();
  fmt.setSamples(4);

  QOpenGLWidget *glWidget = new QOpenGLWidget();
  glWidget->setFormat(fmt);
  this->setViewport(glWidget);
  this->setFrameStyle(QFrame::NoFrame);
  this->setInteractive(true);

  this->setHorizontalScrollBarPolicy(Qt::ScrollBarAlwaysOff);
  this->setVerticalScrollBarPolicy(Qt::ScrollBarAlwaysOff);

  QGraphicsScene *scene = new QGraphicsScene(this);
  this->setScene(scene);

  this->mView = new QMapTileWidget(coords, level, this);
  scene->addItem(this->mView);
  this->mView->setFocus();
}

void QMapWidget::resizeEvent(QResizeEvent *event)
{
  this->mView->setGeometry(QRectF(0, 0, this->width(), this->height()));
  this->centerOn(0.5*this->width(), 0.5*this->height());
  QGraphicsView::resizeEvent(event);
}

void QMapWidget::closeEvent(QCloseEvent *event)
{
  this->setViewport(NULL);
  QGraphicsView::closeEvent(event);
}

void QMapWidget::repaintContents()
{
  this->viewport()->update();
}
